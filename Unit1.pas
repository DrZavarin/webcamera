unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  StdCtrls, ExtCtrls, directshow9, ActiveX, Jpeg, WinInet, IniFiles,
  ComCtrls; //не забудьте добавить выделенные модули


type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Image1: TImage;
    ListBox1: TListBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    function CreateGraph: HResult;
    function Initializ: HResult;
    function CaptureBitmap: HResult;
    procedure Button1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    function SetVideoProperties(pVideoCapture: IBaseFilter):Boolean;
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
//  RecMode: boolean = False;
  DeviceName:OleVariant;
  PropertyName:IPropertyBag;
  pDevEnum:ICreateDEvEnum;
  pEnum:IEnumMoniker;
  pMoniker:IMoniker;

MArray1: array of IMoniker; //Это список моникеров, из которго
//мы потом будем получать необходмый моникер

//интерфейсы
    FGraphBuilder:        IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMux:                 IBaseFilter;
    FSink:                IFileSinkFilter;
    FMediaControl:        IMediaControl;
    FVideoWindow:         IVideoWindow;
    FVideoCaptureFilter:  IBaseFilter;
    FAudioCaptureFilter:  IBaseFilter;
//область вывода изображения
    FVideoRect:           TRect;

    FBaseFilter:          IBaseFilter;
    FSampleGrabber:       ISampleGrabber;
    MediaType:            AM_MEDIA_TYPE;





implementation

{$R *.dfm}

function TForm1.SetVideoProperties(pVideoCapture: IBaseFilter):Boolean;
var
  hr:HRESULT;
  pStreamConfig: IAMStreamConfig;
  pAM_Media: PAMMediaType;
  pvih: PVIDEOINFOHEADER;
  pICGP2: ICaptureGraphBuilder2;
begin

{  pICGP2 := FilterGraph as ICaptureGraphBuilder2;
  hr := pICGP2.FindInterface(@PIN_CATEGORY_CAPTURE, nil, pVideoCapture,
                             IID_IAMStreamConfig, pStreamConfig);

  if (SUCCEEDED(hr)) then begin

    pStreamConfig.GetFormat(pAM_Media);

    pAM_Media.subtype := MEDIASUBTYPE_RGB24;
    pAM_Media.majortype := MEDIATYPE_Video;
    pAM_Media.bFixedSizeSamples := True;
    pAM_Media.bTemporalCompression := False;
    pAM_Media.lSampleSize := 230400;
    pAM_Media.formattype := FORMAT_VideoInfo;
    pAM_Media.pUnk := nil;
    pAM_Media.cbFormat := 88;

    pvih := pAM_Media.pbFormat;
    pvih.dwBitRate := 6912000;
    pvih.AvgTimePerFrame := 10000000 div 15;
    pvih.bmiHeader.biSize := 40;
    pvih.bmiHeader.biWidth := 320;
    pvih.bmiHeader.biHeight := 240;
    pvih.bmiHeader.biPlanes := 1;
    pvih.bmiHeader.biBitCount := 24;
    pvih.bmiHeader.biCompression := 0;
    pvih.bmiHeader.biSizeImage := 230400;
    pvih.bmiHeader.biXPelsPerMeter := 0;
    pvih.bmiHeader.biYPelsPerMeter := 0;
    pvih.bmiHeader.biClrUsed := 0;
    pvih.bmiHeader.biClrImportant := 0;

    hr := pStreamConfig.SetFormat(pAM_Media^);

    If Succeeded(hr) then ShowMessage('SUCCEED') else ShowMessage(IntToStr(hr));
    DeleteMediaType(pAM_Media);
    pStreamConfig := nil;
  end;
 }
end;



function TForm1.Initializ: HResult;
begin
  //Создаем объект для перечисления устройств
   Result:=CoCreateInstance(CLSID_SystemDeviceEnum, NIL, CLSCTX_INPROC_SERVER,
   IID_ICreateDevEnum, pDevEnum);
   if Result<>S_OK then EXIT;

  //Перечислитель устройств Video
   Result:=pDevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, pEnum, 0);
   if Result<>S_OK then EXIT;

  //Обнуляем массив в списке моникеров
   setlength(MArray1,0);

  //Пускаем массив по списку устройств
   while (S_OK=pEnum.Next(1,pMoniker,Nil)) do
    begin
     setlength(MArray1,length(MArray1)+1); //Увеличиваем массив на единицу
     MArray1[length(MArray1)-1]:=pMoniker; //Запоминаем моникер в масиве
     Result:=pMoniker.BindToStorage(NIL, NIL, IPropertyBag, PropertyName); //Линкуем моникер устройства к формату хранения IPropertyBag
     if FAILED(Result) then Continue;
     Result:=PropertyName.Read('FriendlyName', DeviceName, NIL); //Получаем имя устройства
     if FAILED(Result) then Continue;
     //Добавляем имя устройства в списки
     Listbox1.Items.Add(DeviceName);
    end;

   //Первоначальный выбор устройств для захвата видео
   //Выбираем из спика камеру
   if ListBox1.Count=0 then
    begin
      ShowMessage('Камера не обнаружена');
      Result:=E_FAIL;;
      Exit;
   end;
   Listbox1.ItemIndex:=0;
   //если все ОК
   Result:=S_OK;

end;


function TForm1.CreateGraph:HResult;
var
  pConfigMux: IConfigAviMux;
  pvih: PVIDEOINFOHEADER;
begin
//Чистим граф
  FVideoCaptureFilter  := NIL;
  FVideoWindow         := NIL;
  FMediaControl        := NIL;
  FSampleGrabber       := NIL;
  FBaseFilter          := NIL;
  FCaptureGraphBuilder := NIL;
  FGraphBuilder        := NIL;

//Создаем объект для графа фильтров
Result:=CoCreateInstance(CLSID_FilterGraph, NIL, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraphBuilder);
if FAILED(Result) then EXIT;
// Создаем объект для граббинга
Result:=CoCreateInstance(CLSID_SampleGrabber, NIL, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
if FAILED(Result) then EXIT;
//Создаем объект для графа захвата
Result:=CoCreateInstance(CLSID_CaptureGraphBuilder2, NIL, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
if FAILED(Result) then EXIT;

// Добавляем фильтр в граф
Result:=FGraphBuilder.AddFilter(FBaseFilter, 'GRABBER');
if FAILED(Result) then EXIT;
// Получаем интерфейс фильтра перехвата
Result:=FBaseFilter.QueryInterface(IID_ISampleGrabber, FSampleGrabber);
if FAILED(Result) then EXIT;

  if FSampleGrabber <> NIL then
  begin
    //обнуляем память
    ZeroMemory(@MediaType, sizeof(AM_MEDIA_TYPE));
    // Устанавливаем формат данных ля фильтра перехвата

    with MediaType do
    begin
      majortype  := MEDIATYPE_Video;
      subtype    := MEDIASUBTYPE_RGB24;
      formattype := FORMAT_VideoInfo;
    end;


//    pvih := MediaType.pbFormat;




//    label1.Caption:=inttostr(pvih.bmiHeader.biWidth);
//    label2.Caption:=inttostr(pvih.bmiHeader.biHeight);
//    pvih.bmiHeader.biWidth:=320;
//    pvih.bmiHeader.biHeight := 240;


    FSampleGrabber.SetMediaType(MediaType);

    // Данные будут записаны в буфер в том виде, в котором они
    // проходят через фильтр
    FSampleGrabber.SetBufferSamples(TRUE);

    // Граф не будет остановлен для получения кадра
    FSampleGrabber.SetOneShot(FALSE);
  end;

//Задаем граф фильтров
Result:=FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder);
if FAILED(Result) then EXIT;

//выбор устройств ListBox - ов
if Listbox1.ItemIndex>=0 then
           begin
              //получаем устройство для захвата видео из списка моникеров
              MArray1[Listbox1.ItemIndex].BindToObject(NIL, NIL, IID_IBaseFilter, FVideoCaptureFilter);
              //добавляем устройство в граф фильтров
              FGraphBuilder.AddFilter(FVideoCaptureFilter, 'VideoCaptureFilter'); //Получаем фильтр графа захвата
           end;

//Задаем, что откуда будем получать и куда оно должно выводиться
Result:=FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil, FVideoCaptureFilter ,FBaseFilter  ,nil);
if FAILED(Result) then EXIT;

//Получаем интерфейс управления окном видео
Result:=FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);
if FAILED(Result) then EXIT;
//Задаем стиль окна вывода
FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//Накладываем окно вывода на  Panel1
FVideoWindow.put_Owner(Panel1.Handle);
//Задаем размеры окна во всю панель
FVideoRect:=Panel1.ClientRect;
FVideoWindow.SetWindowPosition(FVideoRect.Left,FVideoRect.Top, FVideoRect.Right - FVideoRect.Left,FVideoRect.Bottom - FVideoRect.Top);
//показываем окно
FVideoWindow.put_Visible(TRUE);

//Запрашиваем интерфейс управления графом
Result:=FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
if FAILED(Result) then Exit;
//Запускаем отображение просмотра с вебкамер
FMediaControl.Run();
end;

//с помощью этой функции будем грабить изображение
function TForm1.CaptureBitmap: HResult;
var
  bSize: integer;
  pVideoHeader: TVideoInfoHeader;
  MediaType: TAMMediaType;
  BitmapInfo: TBitmapInfo;
  Buffer: Pointer;
  tmp: array of byte;
  Bitmap: TBitmap;
  JpegIm: TJpegImage;

begin
  // Результат по умолчанию
  Result := E_FAIL;

  // Если  отсутствует интерфейс фильтра перехвата изображения,
  // то завершаем работу
  if FSampleGrabber = NIL then EXIT;

  // Получаем размер кадра
    Result := FSampleGrabber.GetCurrentBuffer(bSize, NIL);
    if (bSize <= 0) or FAILED(Result) then EXIT;
  // Создаем изображение
  Bitmap := TBitmap.Create;
  try
  //обнуляем память
  ZeroMemory(@MediaType, sizeof(TAMMediaType));
  // Получаем тип медиа потока на входе у фильтра перехвата
  Result := FSampleGrabber.GetConnectedMediaType(MediaType);
  if FAILED(Result) then EXIT;

    // Копируем заголовок изображения
    pVideoHeader := TVideoInfoHeader(MediaType.pbFormat^);
    ZeroMemory(@BitmapInfo, sizeof(TBitmapInfo));
    CopyMemory(@BitmapInfo.bmiHeader, @pVideoHeader.bmiHeader, sizeof(TBITMAPINFOHEADER));

    Buffer := NIL;

    // Создаем побитовое изображение
    Bitmap.Handle := CreateDIBSection(0, BitmapInfo, DIB_RGB_COLORS, Buffer, 0, 0);

    // Выделяем память во временном массиве
    SetLength(tmp, bSize);

    try
   //   // Читаем изображение из медиа потока во временный буфер
      FSampleGrabber.GetCurrentBuffer(bSize, @tmp[0]);
  //
      // Копируем данные из временного буфера в наше изображение
      CopyMemory(Buffer, @tmp[0], MediaType.lSampleSize);

      ///если необходимо сохранить изображение в bmp файле
      ///Bitmap.SaveToFile('c:\temp1.bmp');

      // Конвертируем изображение в Jpeg
      //создаем объект JpegImage
      JpegIm := TJpegImage.Create;
      //устанавливаем связь с объектом Bitmap
      JpegIm.Assign(Bitmap);
      //задаем степень сжатия
      JpegIm.CompressionQuality := 95;
      //сжимаем
      JpegIm.Compress;
      //сохраняем в файл
      JpegIm.SaveToFile('c:\temp.jpg');

      image1.Stretch:=true;
      image1.Proportional:=true;
      image1.Picture.LoadFromFile('c:\temp.jpg');
    except

      // В случае сбоя возвращаем ошибочный результат
      Result := E_FAIL;
    end;
  finally
    // Освобождаем память
    SetLength(tmp, 0);
    Bitmap.Free;
    JpegIm.Free;
  end;
end;




procedure TForm1.Button1Click(Sender: TObject);
//Вызов страницы свойств Web-камеры
var
  StreamConfig: IAMStreamConfig;
  PropertyPages: ISpecifyPropertyPages;
  Pages: CAUUID;
  mt:pammediatype;
  mtn:_ammediatype;
  pvih: PVIDEOINFOHEADER;
Begin
//если запись уже идет - выходим
//If RecMode then Exit;
  // Если отсутствует интерфейс работы с видео, то завершаем работу
  if FVideoCaptureFilter = NIL then EXIT;
  // Останавливаем работу графа
  FMediaControl.Stop;
  try
    // Ищем интерфейс управления форматом данных выходного потока
    // Если интерфейс найден, то ...
    if SUCCEEDED(FCaptureGraphBuilder.FindInterface(@PIN_CATEGORY_CAPTURE,
      @MEDIATYPE_Video, FVideoCaptureFilter, IID_IAMStreamConfig, StreamConfig)) then
    begin
      // ... пытаемся найти интерфейс управления страницами свойств ...
      // ... и, если он найден, то ...
      if SUCCEEDED(StreamConfig.QueryInterface(ISpecifyPropertyPages, PropertyPages)) then
      begin
        // ... получаем массив страниц свойств
        PropertyPages.GetPages(Pages);
        PropertyPages := NIL;

        // Отображаем страницу свойств в виде модального диалога

        OleCreatePropertyFrame(
           Handle,
           0,
           0,
           'Camera',
           1,
           @StreamConfig,
           Pages.cElems,
           Pages.pElems,
           0,
           0,
           NIL
        );

        // Освобождаем память
        StreamConfig := NIL;
        CoTaskMemFree(Pages.pElems);
      end;
    end;

  finally
    // Восстанавливаем работу графа
    FMediaControl.Run;
  end;
end;



procedure TForm1.ListBox1DblClick(Sender: TObject);
begin
if ListBox1.Count=0 then
    Begin
       ShowMessage('Камера не найдена');
       Exit;
    End;
//перестраиваем  граф при смене камеры
if FAILED(CreateGraph) then
    Begin
      ShowMessage('Внимание! Произошла ошибка при построении графа фильтров');
      Exit;
    End;
end;



procedure TForm1.Button2Click(Sender: TObject);
var r: HResult;
begin
//грабим кадр
r:=CaptureBitmap;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
//загружаем настройки из ini файла
CoInitialize(nil);// инициализировать OLE COM
//вызываем процедуру поиска и инициализации устройств захвата видео и звука
if FAILED(Initializ) then
    Begin
      ShowMessage('Внимание! Произошла ошибка при инициализации камеры');
      Exit;
    End;
//проверяем найденный список устройств
if Listbox1.Count>0 then
    Begin
        //если необходимые для работы устройства найдены,
        //то вызываем процедуру построения графа фильтров
        if FAILED(CreateGraph) then
            Begin
              ShowMessage('Внимание! Произошла ошибка при построении графа фильтров');
              Exit;
            End;
    end else
            Begin
              ShowMessage('Внимание! Камера не обнаружена.');
              //Application.Terminate;
            End;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
// Освобождаем память
        pEnum := NIL;
        pDevEnum := NIL;
        pMoniker := NIL;
        PropertyName := NIL;
        DeviceName:=Unassigned;
        FGraphBuilder := nil;
        FMediaControl.Stop;
        FMediaControl := nil;
        FVideoWindow.put_Visible(false);
        FVideoWindow := nil;
        CoUninitialize;// деинициализировать OLE COM
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
FMediaControl.Run;
FVideoWindow.put_Visible(true);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
FMediaControl.StopWhenReady;
FVideoWindow.put_Visible(false);
end;

end.
