object Form1: TForm1
  Left = 199
  Top = 136
  Width = 1546
  Height = 785
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 24
    Top = 24
    Width = 577
    Height = 425
    Caption = 'Panel1'
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 832
    Top = 24
    Width = 561
    Height = 425
    Caption = 'Panel2'
    TabOrder = 1
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 561
      Height = 425
    end
  end
  object ListBox1: TListBox
    Left = 32
    Top = 552
    Width = 313
    Height = 105
    ItemHeight = 13
    TabOrder = 2
    OnDblClick = ListBox1DblClick
  end
  object Button1: TButton
    Left = 32
    Top = 672
    Width = 313
    Height = 25
    Caption = 'Camera options'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 672
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Snap'
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 384
    Top = 592
    Width = 145
    Height = 25
    Caption = 'Close camera'
    TabOrder = 5
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 384
    Top = 552
    Width = 145
    Height = 25
    Caption = 'Init camera'
    TabOrder = 6
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 384
    Top = 632
    Width = 145
    Height = 25
    Caption = 'Run view'
    TabOrder = 7
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 384
    Top = 672
    Width = 145
    Height = 25
    Caption = 'Stop view'
    TabOrder = 8
    OnClick = Button6Click
  end
end
