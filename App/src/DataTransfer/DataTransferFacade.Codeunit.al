/// <summary>
/// Provides the same functionality as the DataTransfer type,
/// if run outside of install or upgrade execution context RecordRef and FieldRef are used to transfer the data instead od DataTransfer
/// </summary>
codeunit 50102 "DataTransfer Facade"
{

    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DataTransferHelper: Codeunit "DataTransfer Helper";

    /// <summary>
    /// Sets the source and destination tables for the data transfer.
    /// </summary>
    /// <param name="SourceTableId">The source table for the transfer.</param>
    /// <param name="DestTableId">The destination table for the transfer.</param>
    procedure SetTables(SourceTableId: Integer; DestTableId: Integer)
    begin
        DataTransferHelper.SetTables(SourceTableId, DestTableId);
    end;

    /// <summary>
    /// Copies the rows from the source table to the destination table with the fields selected with AddFields and the filters applied with AddSourceFilter.
    /// If the code is run inside install or upgrade execution context the data is copied in one bulk operation in SQL.
    /// If the code is run outside of install or upgrade execution context RecordRef and FieldRef are used to transfer the data.
    /// </summary>
    procedure CopyRows()
    begin
        DataTransferHelper.CopyRows();
    end;

    /// <summary>
    /// Copies the fields specified in AddFields with filters from AddSourceFilter, and the join conditions from AddJoins.
    /// If the code is run inside install or upgrade execution context the data is copied in one bulk operation in SQL.
    /// If the code is run outside of install or upgrade execution context RecordRef and FieldRef are used to transfer the data.
    /// </summary>
    procedure CopyFields()
    begin
        DataTransferHelper.CopyFields();
    end;

    /// <summary>
    /// Specifies the given value is to be set in the given field in the destination table.
    /// </summary>
    /// <param name="Value">The value to set in the destination field.</param>
    /// <param name="DestFieldNo">The destination table field.</param>
    procedure AddConstantValue(Value: Variant; DestFieldNo: Integer)
    begin
        DataTransferHelper.AddConstantValue(Value, DestFieldNo);
    end;

    /// <summary>
    /// Specifies a source and destination field, where the values from the source field are to be copied to the destination field. The data types of the fields must match, except CODE to TEXT which is allowed.
    /// </summary>
    /// <param name="SourceFieldNo">The source table field.</param>
    /// <param name="DestFieldNo">The destination table field.</param>
    procedure AddFieldValue(SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        DataTransferHelper.AddFieldValue(SourceFieldNo, DestFieldNo);
    end;

    /// <summary>
    /// Adds a field pair to be used to create a join condition which determines which rows to transfer, optional for same table transfers.
    /// </summary>
    /// <param name="SourceFieldNo">The source table field.</param>
    /// <param name="DestFieldNo">The destination table field.</param>
    procedure AddJoin(SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        DataTransferHelper.AddJoin(SourceFieldNo, DestFieldNo);
    end;

    /// <summary>
    /// Adds a filter for the source table for the data transfer.
    /// </summary>
    /// <param name="SourceFieldNo">The source table field.</param>
    /// <param name="FilterText">The filter expression.2</param>
    procedure AddSourceFilter(SourceFieldNo: Integer; FilterText: Text)
    begin
        DataTransferHelper.AddSourceFilter(SourceFieldNo, FilterText);
    end;

    /// <summary>
    /// Cleans up the data transfer. Should be invoked if the same instance is used for multiple data transfers.
    /// </summary>
    procedure Clean()
    begin
        DataTransferHelper.Clean();
    end;
}