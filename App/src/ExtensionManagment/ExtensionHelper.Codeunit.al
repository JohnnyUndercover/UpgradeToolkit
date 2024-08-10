codeunit 50101 "Extension Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region external procedures
    /// <summary>
    /// ReInstalls an extension.
    /// Uninstalls the extension and all dependent extensions and then installs it again.
    /// </summary>
    /// <param name="PackageId">The ID of the extension package.</param>
    /// <param name="lcid">The Locale Identifier.</param>
    /// <param name="IsUIEnabled">Indicates if the reinstall operation is invoked through the UI.</param>
    /// <returns>True if the operation was successful and false otherwise.</returns>
    internal procedure ReinstallExtension(PackageId: Guid; lcid: Integer; IsUIEnabled: Boolean): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
        DependentModules: List of [ModuleInfo];
        DependentModule: ModuleInfo;
        Success: Boolean;
    begin
        Success := true;
        DependentModules := GetDependentModulesForExtensionToReinstall(PackageId);

        if not ExtensionManagement.UninstallExtension(PackageId, IsUIEnabled) then
            Success := false;

        if not ExtensionManagement.InstallExtension(PackageId, lcid, IsUIEnabled) then
            Success := false;

        foreach DependentModule in DependentModules do
            if not ExtensionManagement.InstallExtension(DependentModule.PackageId, lcid, IsUIEnabled) then
                Success := false;

        exit(Success);
    end;

    internal procedure GetDependentAppsForAllInstalledApps(): Dictionary of [ModuleInfo, List of [ModuleInfo]]
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
        DependentApps: List of [ModuleInfo];
        AppDependencies: Dictionary of [ModuleInfo, List of [ModuleInfo]];
        App: ModuleInfo;
    begin
        if not NAVAppInstalledApp.FindSet() then
            exit;
        repeat
            Clear(DependentApps);
            NavApp.GetModuleInfo(NAVAppInstalledApp."App ID", App);
            GetDependentApps(App, DependentApps);
            AppDependencies.Add(App, DependentApps);
        until NAVAppInstalledApp.Next() = 0;
        exit(AppDependencies);
    end;
    #endregion external procedures

    local procedure GetDependentModulesForExtensionToReinstall(PackageId: Guid): List of [ModuleInfo]
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
        App: ModuleInfo;
    begin
        NAVAppInstalledApp.SetRange("Package ID", PackageId);
        NAVAppInstalledApp.FindFirst();
        NavApp.GetModuleInfo(NAVAppInstalledApp."App ID", App);
        exit(GetDependentApps(App));
    end;



    local procedure GetDependentApps(App: ModuleInfo): List of [ModuleInfo]
    var
        DependentApps: List of [ModuleInfo];
    begin
        GetDependentApps(App, DependentApps);
        exit(DependentApps);
    end;

    local procedure GetDependentApps(App: ModuleInfo; var DependentApps: List of [ModuleInfo])
    var
        Dependency: ModuleDependencyInfo;
        DependencyApp: ModuleInfo;
    begin
        foreach Dependency in App.Dependencies() do begin
            NavApp.GetModuleInfo(Dependency.Id, DependencyApp);
            if not DependentApps.Contains(DependencyApp) then
                DependentApps.Add(DependencyApp);
            GetDependentApps(DependencyApp, DependentApps);
        end;
    end;

}