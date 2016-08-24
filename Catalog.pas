unit Catalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, db, sqldb, Forms, Controls, Dialogs, ExtCtrls, DBGrids, StdCtrls,
  Buttons, Metadata, Grids, FileCtrl, DbCtrls, Editor, sysUtils, FilterFrm,
  MiniFilterFrm;

type

  { TDirectory }

  TDirectory = class(TForm)
    AddFilter: TSpeedButton;
    MiniFilterFrame1: TMiniFilterFrame;
  private
    fTable: TTable;
    fQuary: string;
  published
    FilterLabel: TLabel;
    FilterPanel: TPanel;
    OrderField: TFilterComboBox;
    OrderWay: TFilterComboBox;
    OrderLabel: TLabel;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    GridPanel: TPanel;
    ControlPanel: TPanel;
    AddBtn: TSpeedButton;
    EditBtn: TSpeedButton;
    DelBtn: TSpeedButton;
    SerchBtn: TSpeedButton;
    RefreshBtn: TSpeedButton;
    SQLQuery: TSQLQuery;
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure AddBtnClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure SerchBtnClick(Sender: TObject);
    procedure AddFilterClick(Sender: TObject);
    constructor CreateCatalog(TheOwner: TComponent; aTable: TTable);
  end;

implementation

{$R *.lfm}

function GenSelectSQL(aTable: TTable): string;
var
  i: integer;
begin
  Result := 'SELECT ';
  with aTable do
    for i := 0 to High(Columns) do begin
      if i > 0 then Result += ', ';
      with Columns[i] do begin
        Result += NameTable + '.' + DataField;
        if Primary then
          Result += ', ' + KeyTable + '.' + ListField;
      end;
    end;
end;

function GenJoinSQL(aTable: TTable): string;
var
  i: integer;
begin
  with aTable do begin
    Result := NameTable;
    for i := 0 to High(Columns) do
      with Columns[i] do
        if Primary then
          Result += ' INNER JOIN ' + KeyTable + ' ON '
                 + NameTable + '.' + DataField + ' = '
                 + KeyTable + '.' + KeyField;
  end;
end;

function GetOrderFields(aTable: TTable): string;
const
  CQuery = '%s|ORDER BY %s.%s|';
var
  i: integer;
begin
  Result := '';
  with aTable do
    for i := 0 to High(Columns) do
      with Columns[i] do
        if Primary then
          Result += Format(CQuery, [CaptionField, KeyTable, ListField])
        else
          Result += Format(CQuery, [CaptionField, NameTable, DataField]);

  Result := LeftStr(Result, Length(Result) - 1);
end;

function GenFromSQL(aTable: TTable): string;
begin
  Result := 'FROM ' + GenJoinSQL(aTable);
end;

constructor TDirectory.CreateCatalog(TheOwner: TComponent; aTable: TTable);
var
  i: integer;
begin
  Tag := TheOwner.Tag;
  inherited Create(TheOwner);
  fTable := aTable;

  with fTable do begin
    Caption := CaptionTable;
    // Подготовка таблицы (установка имен, ширины столбцов)
    for i := 0 to High(Columns) do
      with DBGrid.Columns.Add, Columns[i] do begin
        if Primary then
          FieldName := ListField
        else
          FieldName := DataField;

        Title.Caption := CaptionField;
        Width := 10 + Canvas.TextWidth(Title.Caption);
      end;
  end;

  OrderField.Filter := GetOrderFields(aTable);
  SQLQuery.SQL.Append(GenSelectSQL(atable));
  SQLQuery.SQL.Append(GenFromSQL(atable));
  fQuary := SQLQuery.SQL.Text;
  ShowMessage(fQuary);
  SQLQuery.Open;
end;

procedure TDirectory.RefreshBtnClick(Sender: TObject);
begin
  SQLQuery.SQL.Text := fQuary;
  SQLQuery.Refresh;
end;

procedure TDirectory.SerchBtnClick(Sender: TObject);
var
  i: integer;
begin
  SQLQuery.SQL.Text := fQuary;
  SQLQuery.SQL.Append('WHERE ' + MiniFilterFrame1.CompileFilter);

  for i := 0 to FilterPanel.ComponentCount - 1 do
    if FilterPanel.Components[i] is TFilterFrame then
      SQLQuery.SQL.Append((FilterPanel.Components[i] as TFilterFrame).CompileFilter);

  SQLQuery.SQL.Append(OrderField.Mask + OrderWay.Mask);
  ShowMessage(SQLQuery.SQL.Text);
  SQLQuery.Refresh;
end;

procedure TDirectory.AddFilterClick(Sender: TObject);
begin
  TFilterFrame.Create(FilterPanel);
end;

procedure TDirectory.DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  MaxWidth: integer = 10;
begin
  MaxWidth += Canvas.TextWidth(Column.Field.Text);
  if MaxWidth > Column.Width then
    Column.Width := MaxWidth;
end;

procedure TDirectory.DelBtnClick(Sender: TObject);
var
  selected: integer;
begin
  selected := MessageDlg('Вы уверены, что хотите удалить выбранную запись?',
                           mtConfirmation, [mbYes, mbNo], 0);
  if selected = mrYes then
    TCellEditor.CreateAndDel(Self, fTable, SQLQuery).Free;
end;

procedure TDirectory.EditBtnClick(Sender: TObject);
begin
  TCellEditor.CreateAndEdit(Self, fTable, SQLQuery).ShowModal;
end;

procedure TDirectory.AddBtnClick(Sender: TObject);
begin
  TCellEditor.CreateAndAdd(Self, fTable, SQLQuery).ShowModal;
end;

end.

