/// <summary>
/// Provides the same functionality as the DataTransfer type,
/// if run outside of install or upgrade execution context RecordRef and FieldRef are used to transfer the data instead od DataTransfer
/// </summary>
codeunit 50100 "DataTransfer Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        _Fields: Dictionary of [Integer, Integer];
        _JoinFields: Dictionary of [Integer, Integer];
        _Constants: Dictionary of [Integer, Text];
        _SourceFilters: Dictionary of [Integer, Text];
        _DestTableId: Integer;
        _SourceTableId: Integer;
        JoinFieldRequiredErr: Label 'Data transfers between different tables must specify a join condition.', Locked = true;
        SystemCreatedAtErr: Label 'SystemCreatedAt must not be in the list of fields to copy.', Locked = true;
        SystemCreatedByErr: Label 'SystemCreatedBy must not be in the list of fields to copy.', Locked = true;
        SystemIdErr: Label 'SystemId must not be in the list of fields to copy.', Locked = true;
        SystemModifiedAtErr: Label 'SystemModifiedAt must not be in the list of fields to copy.', Locked = true;
        SystemModifiedByErr: Label 'SystemModifiedBy must not be in the list of fields to copy.', Locked = true;
        SystemRowVersionErr: Label 'SystemRowVersion must not be in the list of fields to copy.', Locked = true;

    #region external procedures
    internal procedure SetTables(SourceTableId: Integer; DestTableId: Integer)
    begin
        _SourceTableId := SourceTableId;
        _DestTableId := DestTableId;
    end;

    internal procedure CopyRows()
    begin
        if GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            CopyRowsWithDataTransfer()
        else
            CopyRowsWithRecRef();
    end;

    internal procedure CopyFields()
    begin
        if GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            CopyFieldsWithDataTransfer()
        else
            CopyFieldsWithRecRef();
    end;

    internal procedure AddConstantValue(Value: Variant; DestFieldNo: Integer)
    begin
        _Constants.Add(DestFieldNo, Format(Value, 0, 9));
    end;

    internal procedure AddFieldValue(SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        _Fields.Add(SourceFieldNo, DestFieldNo);
    end;

    internal procedure AddJoin(SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        _JoinFields.Add(SourceFieldNo, DestFieldNo);
    end;

    internal procedure AddSourceFilter(SourceFieldNo: Integer; FilterText: Text)
    begin
        _SourceFilters.Add(SourceFieldNo, FilterText);
    end;

    internal procedure Clean()
    begin
        Clear(_Fields);
        Clear(_Constants);
        Clear(_SourceFilters);
        Clear(_SourceTableId);
        Clear(_DestTableId);
        Clear(_JoinFields);
    end;
    #endregion external procedures

    #region local procedures for implementation

    #region DataTransfer implementation
    local procedure CopyRowsWithDataTransfer()
    var
        DestRecRef: RecordRef;
        ConstValueFieldRef: FieldRef;
        DataTrans: DataTransfer;
        ConstFieldNo: Integer;
        FieldNo: Integer;
        SourceFilterFieldNo: Integer;
    begin
        DataTrans.SetTables(_SourceTableId, _DestTableId);

        DestRecRef.Open(_DestTableId);
        foreach ConstFieldNo in _Constants.Keys do begin
            ConstValueFieldRef := DestRecRef.Field(ConstFieldNo);
            Evaluate(ConstValueFieldRef, _Constants.Get(ConstFieldNo), 9);
            DataTrans.AddConstantValue(ConstValueFieldRef.Value, ConstFieldNo);
        end;

        foreach SourceFilterFieldNo in _SourceFilters.Keys do begin
            DataTrans.AddSourceFilter(SourceFilterFieldNo, _SourceFilters.Get(SourceFilterFieldNo));
        end;

        foreach FieldNo in _Fields.Keys do begin
            DataTrans.AddFieldValue(FieldNo, _Fields.Get(FieldNo));
        end;

        DataTrans.CopyRows();
    end;

    local procedure CopyFieldsWithDataTransfer()
    var
        DestRecRef: RecordRef;
        ConstValueFieldRef: FieldRef;
        DataTrans: DataTransfer;
        ConstFieldNo: Integer;
        FieldNo: Integer;
        JoinFieldNo: Integer;
        SourceFilterFieldNo: Integer;
    begin
        DataTrans.SetTables(_SourceTableId, _DestTableId);

        DestRecRef.Open(_DestTableId);
        foreach ConstFieldNo in _Constants.Keys do begin
            ConstValueFieldRef := DestRecRef.Field(ConstFieldNo);
            Evaluate(ConstValueFieldRef, _Constants.Get(ConstFieldNo), 9);
            DataTrans.AddConstantValue(ConstValueFieldRef.Value, ConstFieldNo);
        end;

        foreach SourceFilterFieldNo in _SourceFilters.Keys do begin
            DataTrans.AddSourceFilter(SourceFilterFieldNo, _SourceFilters.Get(SourceFilterFieldNo));
        end;

        foreach FieldNo in _Fields.Keys do begin
            DataTrans.AddFieldValue(FieldNo, _Fields.Get(FieldNo));
        end;

        foreach JoinFieldNo in _JoinFields.Keys do begin
            DataTrans.AddJoin(JoinFieldNo, _JoinFields.Get(JoinFieldNo));
        end;

        DataTrans.CopyFields();
    end;
    #endregion DataTransfer implementation

    #region RecordRef implementation
    local procedure CopyRowsWithRecRef()
    var
        DestRecRef: RecordRef;
        SourceRecRef: RecordRef;
    begin
        if _Fields.ContainsKey(0) then
            Error(SystemRowVersionErr);

        DestRecRef.Open(_DestTableId);
        SourceRecRef.Open(_SourceTableId);
        SetSourceFilters(SourceRecRef);
        if SourceRecRef.FindSet() then
            repeat
                CopyFieldValues(SourceRecRef, DestRecRef);
                CopyConstantValues(DestRecRef);
                if _Fields.ContainsKey(SourceRecRef.SystemIdNo) then
                    DestRecRef.Insert(false, true)
                else
                    DestRecRef.Insert(false);
            until SourceRecRef.Next() = 0;
    end;

    local procedure CopyFieldsWithRecRef()
    var
        DestRecRef: RecordRef;
        SourceRecRef: RecordRef;
        JoinNotUnqiueErr: Label 'The values of the fields specified by the join condition in the source table does not produce a unique set, it is therefore indeterminate which value would be transfered.The values of the fields specified by the join condition in the source table do not produce a unique set, it is therefore indeterminate which value would be transferred.', Locked = true;
    begin
        if _SourceTableId <> _DestTableId then
            if _JoinFields.Count < 1 then
                Error(JoinFieldRequiredErr);

        if _Fields.ContainsKey(SourceRecRef.SystemIdNo) then
            Error(SystemIdErr);
        if _Fields.ContainsKey(0) then
            Error(SystemRowVersionErr);
        if _Fields.ContainsKey(SourceRecRef.SystemCreatedAtNo) then
            Error(SystemCreatedAtErr);
        if _Fields.ContainsKey(SourceRecRef.SystemCreatedByNo) then
            Error(SystemCreatedByErr);
        if _Fields.ContainsKey(SourceRecRef.SystemModifiedAtNo) then
            Error(SystemModifiedAtErr);
        if _Fields.ContainsKey(SourceRecRef.SystemModifiedByNo) then
            Error(SystemModifiedByErr);

        DestRecRef.Open(_DestTableId);
        SourceRecRef.Open(_SourceTableId);
        SetSourceFilters(SourceRecRef);
        if SourceRecRef.FindSet() then
            repeat
                if _SourceTableId = _DestTableId then begin
                    DestRecRef.Get(SourceRecRef.RecordId);
                    CopyFieldValues(SourceRecRef, DestRecRef);
                    CopyConstantValues(DestRecRef);
                    DestRecRef.Modify(false);
                end else begin
                    ApplyJoin(SourceRecRef, DestRecRef);
                    if DestRecRef.Count() > 1 then
                        Error(JoinNotUnqiueErr);

                    CopyFieldValues(SourceRecRef, DestRecRef);
                    CopyConstantValues(DestRecRef);
                    DestRecRef.Modify(false);
                end;

            until SourceRecRef.Next() = 0;
    end;

    local procedure SetSourceFilters(var SourceRecRef: RecordRef)
    var
        SourceFieldRef: FieldRef;
        FieldNo: Integer;
    begin
        foreach FieldNo in _SourceFilters.Keys do begin
            SourceFieldRef := SourceRecRef.Field(FieldNo);
            SourceFieldRef.SetFilter(_SourceFilters.Get(FieldNo));
        end;
    end;

    local procedure CopyFieldValues(var SourceRecRef: RecordRef; var DestRecRef: RecordRef)
    var
        DestFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        DestFieldNo: Integer;
        SourceFieldNo: Integer;
    begin
        foreach SourceFieldNo in _Fields.Keys do begin
            DestFieldNo := _Fields.Get(SourceFieldNo);
            SourceFieldRef := SourceRecRef.Field(SourceFieldNo);
            DestFieldRef := DestRecRef.Field(DestFieldNo);
            if SourceFieldRef.Type = SourceFieldRef.Type::Blob then
                SourceFieldRef.CalcField();
            DestFieldRef.Value := SourceFieldRef.Value;
        end;
    end;

    local procedure CopyConstantValues(var DestRecRef: RecordRef)
    var
        DestFieldRef: FieldRef;
        DestFieldNo: Integer;
    begin
        foreach DestFieldNo in _Constants.Keys do begin
            DestFieldRef := DestRecRef.Field(DestFieldNo);
            Evaluate(DestFieldRef, _Constants.Get(DestFieldNo), 9);
        end;
    end;

    local procedure ApplyJoin(var SourceRecRef: RecordRef; var DestRecRef: RecordRef)
    var
        DestFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        JoinDestFieldNo: Integer;
        JoinSourceFieldNo: Integer;
    begin
        foreach JoinSourceFieldNo in _JoinFields.Keys do begin
            JoinDestFieldNo := _JoinFields.Get(JoinSourceFieldNo);
            SourceFieldRef := SourceRecRef.Field(JoinSourceFieldNo);
            DestFieldRef := DestRecRef.Field(JoinDestFieldNo);
            DestFieldRef.SetRange(SourceFieldRef.Value);
        end;
    end;
    #endregion RecordRef implementation

    #endregion local procedures for implementation
}