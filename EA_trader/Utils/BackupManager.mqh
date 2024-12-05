//+------------------------------------------------------------------+
//|                                                BackupManager.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"
class CBackupManager {
private:
    string backupPath;
    datetime lastBackup;
    
public:
    bool CreateBackup();
    bool RestoreFromBackup();
    void CleanOldBackups();
};