codeunit 50103 "Extension Managment Facade"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ExtensionHelper: Codeunit "Extension Helper";


    /// <summary>
    /// ReInstalls an extension.
    /// Uninstalls the extension and all dependent extensions and then installs it again.
    /// </summary>
    /// <param name="PackageId">The ID of the extension package.</param>
    /// <param name="lcid">The Locale Identifier.</param>
    /// <param name="IsUIEnabled">Indicates if the reinstall operation is invoked through the UI.</param>
    /// <returns>True if the operation was successful and false otherwise.</returns>
    internal procedure ReinstallExtension(PackageId: Guid; lcid: Integer; IsUIEnabled: Boolean): Boolean
    begin
        exit(ExtensionHelper.ReinstallExtension(PackageId, lcid, IsUIEnabled))
    end;

    /// <summary>
    /// Gets a dictionary with all installed extensions and their dependent extensions.
    /// </summary>
    /// <returns>A dictionary with all installed extensions and their dependent extensions.</returns>
    internal procedure GetDependentAppsForAllInstalledApps(): Dictionary of [ModuleInfo, List of [ModuleInfo]]
    begin
        exit(ExtensionHelper.GetDependentAppsForAllInstalledApps());
    end;
}