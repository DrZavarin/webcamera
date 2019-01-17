unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  StdCtrls, ExtCtrls, directshow9, ActiveX, Jpeg, WinInet, IniFiles,
  ComCtrls; //�� �������� �������� ���������� ������


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

MArray1: array of IMoniker; //��� ������ ���������, �� �������
//�� ����� ����� �������� ���������� �������

//����������
    FGraphBuilder:        IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMux:                 IBaseFilter;
    FSink:                IFileSinkFilter;
    FMediaControl:        IMediaControl;
    FVideoWindow:         IVideoWindow;
    FVideoCaptureFilter:  IBaseFilter;
    FAudioCaptureFilter:  IBaseFilter;
//������� ������ �����������
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
  //������� ������ ��� ������������ ���������
   Result:=CoCreateInstance(CLSID_SystemDeviceEnum, NIL, CLSCTX_INPROC_SERVER,
   IID_ICreateDevEnum, pDevEnum);
   if Result<>S_OK then EXIT;

  //������������� ��������� Video
   Result:=pDevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, pEnum, 0);
   if Result<>S_OK then EXIT;

  //�������� ������ � ������ ���������
   setlength(MArray1,0);

  //������� ������ �� ������ ���������
   while (S_OK=pEnum.Next(1,pMoniker,Nil)) do
    begin
     setlength(MArray1,length(MArray1)+1); //����������� ������ �� �������
     MArray1[length(MArray1)-1]:=pMoniker; //���������� ������� � ������
     Result:=pMoniker.BindToStorage(NIL, NIL, IPropertyBag, PropertyName); //������� ������� ���������� � ������� �������� IPropertyBag
     if FAILED(Result) then Continue;
     Result:=PropertyName.Read('FriendlyName', DeviceName, NIL); //�������� ��� ����������
     if FAILED(Result) then Continue;
     //��������� ��� ���������� � ������
     Listbox1.Items.Add(DeviceName);
    end;

   //�������������� ����� ��������� ��� ������� �����
   //�������� �� ����� ������
   if ListBox1.Count=0 then
    begin
      ShowMessage('������ �� ����������');
      Result:=E_FAIL;;
      Exit;
   end;
   Listbox1.ItemIndex:=0;
   //���� ��� ��
   Result:=S_OK;

end;


function TForm1.CreateGraph:HResult;
var
  pConfigMux: IConfigAviMux;
  pvih: PVIDEOINFOHEADER;
begin
//������ ����
  FVideoCaptureFilter  := NIL;
  FVideoWindow         := NIL;
  FMediaControl        := NIL;
  FSampleGrabber       := NIL;
  FBaseFilter          := NIL;
  FCaptureGraphBuilder := NIL;
  FGraphBuilder        := NIL;

//������� ������ ��� ����� ��������
Result:=CoCreateInstance(CLSID_FilterGraph, NIL, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraphBuilder);
if FAILED(Result) then EXIT;
// ������� ������ ��� ���������
Result:=CoCreateInstance(CLSID_SampleGrabber, NIL, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
if FAILED(Result) then EXIT;
//������� ������ ��� ����� �������
Result:=CoCreateInstance(CLSID_CaptureGraphBuilder2, NIL, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
if FAILED(Result) then EXIT;

// ��������� ������ � ����
Result:=FGraphBuilder.AddFilter(FBaseFilter, 'GRABBER');
if FAILED(Result) then EXIT;
// �������� ��������� ������� ���������
Result:=FBaseFilter.QueryInterface(IID_ISampleGrabber, FSampleGrabber);
if FAILED(Result) then EXIT;

  if FSampleGrabber <> NIL then
  begin
    //�������� ������
    ZeroMemory(@MediaType, sizeof(AM_MEDIA_TYPE));
    // ������������� ������ ������ �� ������� ���������

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

    // ������ ����� �������� � ����� � ��� ����, � ������� ���
    // �������� ����� ������
    FSampleGrabber.SetBufferSamples(TRUE);

    // ���� �� ����� ���������� ��� ��������� �����
    FSampleGrabber.SetOneShot(FALSE);
  end;

//������ ���� ��������
Result:=FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder);
if FAILED(Result) then EXIT;

//����� ��������� ListBox - ��
if Listbox1.ItemIndex>=0 then
           begin
              //�������� ���������� ��� ������� ����� �� ������ ���������
              MArray1[Listbox1.ItemIndex].BindToObject(NIL, NIL, IID_IBaseFilter, FVideoCaptureFilter);
              //��������� ���������� � ���� ��������
              FGraphBuilder.AddFilter(FVideoCaptureFilter, 'VideoCaptureFilter'); //�������� ������ ����� �������
           end;

//������, ��� ������ ����� �������� � ���� ��� ������ ����������
Result:=FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil, FVideoCaptureFilter ,FBaseFilter  ,nil);
if FAILED(Result) then EXIT;

//�������� ��������� ���������� ����� �����
Result:=FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);
if FAILED(Result) then EXIT;
//������ ����� ���� ������
FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//����������� ���� ������ ��  Panel1
FVideoWindow.put_Owner(Panel1.Handle);
//������ ������� ���� �� ��� ������
FVideoRect:=Panel1.ClientRect;
FVideoWindow.SetWindowPosition(FVideoRect.Left,FVideoRect.Top, FVideoRect.Right - FVideoRect.Left,FVideoRect.Bottom - FVideoRect.Top);
//���������� ����
FVideoWindow.put_Visible(TRUE);

//����������� ��������� ���������� ������
Result:=FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
if FAILED(Result) then Exit;
//��������� ����������� ��������� � ��������
FMediaControl.Run();
end;

//� ������� ���� ������� ����� ������� �����������
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
  // ��������� �� ���������
  Result := E_FAIL;

  // ����  ����������� ��������� ������� ��������� �����������,
  // �� ��������� ������
  if FSampleGrabber = NIL then EXIT;

  // �������� ������ �����
    Result := FSampleGrabber.GetCurrentBuffer(bSize, NIL);
    if (bSize <= 0) or FAILED(Result) then EXIT;
  // ������� �����������
  Bitmap := TBitmap.Create;
  try
  //�������� ������
  ZeroMemory(@MediaType, sizeof(TAMMediaType));
  // �������� ��� ����� ������ �� ����� � ������� ���������
  Result := FSampleGrabber.GetConnectedMediaType(MediaType);
  if FAILED(Result) then EXIT;

    // �������� ��������� �����������
    pVideoHeader := TVideoInfoHeader(MediaType.pbFormat^);
    ZeroMemory(@BitmapInfo, sizeof(TBitmapInfo));
    CopyMemory(@BitmapInfo.bmiHeader, @pVideoHeader.bmiHeader, sizeof(TBITMAPINFOHEADER));

    Buffer := NIL;

    // ������� ��������� �����������
    Bitmap.Handle := CreateDIBSection(0, BitmapInfo, DIB_RGB_COLORS, Buffer, 0, 0);

    // �������� ������ �� ��������� �������
    SetLength(tmp, bSize);

    try
   //   // ������ ����������� �� ����� ������ �� ��������� �����
      FSampleGrabber.GetCurrentBuffer(bSize, @tmp[0]);
  //
      // �������� ������ �� ���������� ������ � ���� �����������
      CopyMemory(Buffer, @tmp[0], MediaType.lSampleSize);

      ///���� ���������� ��������� ����������� � bmp �����
      ///Bitmap.SaveToFile('c:\temp1.bmp');

      // ������������ ����������� � Jpeg
      //������� ������ JpegImage
      JpegIm := TJpegImage.Create;
      //������������� ����� � �������� Bitmap
      JpegIm.Assign(Bitmap);
      //������ ������� ������
      JpegIm.CompressionQuality := 95;
      //�������
      JpegIm.Compress;
      //��������� � ����
      JpegIm.SaveToFile('c:\temp.jpg');

      image1.Stretch:=true;
      image1.Proportional:=true;
      image1.Picture.LoadFromFile('c:\temp.jpg');
    except

      // � ������ ���� ���������� ��������� ���������
      Result := E_FAIL;
    end;
  finally
    // ����������� ������
    SetLength(tmp, 0);
    Bitmap.Free;
    JpegIm.Free;
  end;
end;




procedure TForm1.Button1Click(Sender: TObject);
//����� �������� ������� Web-������
var
  StreamConfig: IAMStreamConfig;
  PropertyPages: ISpecifyPropertyPages;
  Pages: CAUUID;
  mt:pammediatype;
  mtn:_ammediatype;
  pvih: PVIDEOINFOHEADER;
Begin
//���� ������ ��� ���� - �������
//If RecMode then Exit;
  // ���� ����������� ��������� ������ � �����, �� ��������� ������
  if FVideoCaptureFilter = NIL then EXIT;
  // ������������� ������ �����
  FMediaControl.Stop;
  try
    // ���� ��������� ���������� �������� ������ ��������� ������
    // ���� ��������� ������, �� ...
    if SUCCEEDED(FCaptureGraphBuilder.FindInterface(@PIN_CATEGORY_CAPTURE,
      @MEDIATYPE_Video, FVideoCaptureFilter, IID_IAMStreamConfig, StreamConfig)) then
    begin
      // ... �������� ����� ��������� ���������� ���������� ������� ...
      // ... �, ���� �� ������, �� ...
      if SUCCEEDED(StreamConfig.QueryInterface(ISpecifyPropertyPages, PropertyPages)) then
      begin
        // ... �������� ������ ������� �������
        PropertyPages.GetPages(Pages);
        PropertyPages := NIL;

        // ���������� �������� ������� � ���� ���������� �������

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

        // ����������� ������
        StreamConfig := NIL;
        CoTaskMemFree(Pages.pElems);
      end;
    end;

  finally
    // ��������������� ������ �����
    FMediaControl.Run;
  end;
end;



procedure TForm1.ListBox1DblClick(Sender: TObject);
begin
if ListBox1.Count=0 then
    Begin
       ShowMessage('������ �� �������');
       Exit;
    End;
//�������������  ���� ��� ����� ������
if FAILED(CreateGraph) then
    Begin
      ShowMessage('��������! ��������� ������ ��� ���������� ����� ��������');
      Exit;
    End;
end;



procedure TForm1.Button2Click(Sender: TObject);
var r: HResult;
begin
//������ ����
r:=CaptureBitmap;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
//��������� ��������� �� ini �����
CoInitialize(nil);// ���������������� OLE COM
//�������� ��������� ������ � ������������� ��������� ������� ����� � �����
if FAILED(Initializ) then
    Begin
      ShowMessage('��������! ��������� ������ ��� ������������� ������');
      Exit;
    End;
//��������� ��������� ������ ���������
if Listbox1.Count>0 then
    Begin
        //���� ����������� ��� ������ ���������� �������,
        //�� �������� ��������� ���������� ����� ��������
        if FAILED(CreateGraph) then
            Begin
              ShowMessage('��������! ��������� ������ ��� ���������� ����� ��������');
              Exit;
            End;
    end else
            Begin
              ShowMessage('��������! ������ �� ����������.');
              //Application.Terminate;
            End;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
// ����������� ������
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
        CoUninitialize;// ������������������ OLE COM
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
