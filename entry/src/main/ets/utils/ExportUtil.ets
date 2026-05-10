import { fileIo, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Record } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';

/**
 * 数据导出工具
 * 支持 CSV 文件生成与保存
 */
export class ExportUtil {
  private static db: RecordDatabase = RecordDatabase.getInstance();

  /**
   * 读取所有记录，生成 CSV 字符串
   */
  static async buildCSVContent(): Promise<string> {
    const records: Record[] = await ExportUtil.db.getAllRecords();
    if (records.length === 0) {
      return '';
    }
    // BOM 保证 Excel 正确识别 UTF-8
    const bom: string = '\uFEFF';
    const header: string = '日期,类型,分类,金额,备注';
    const rows: string[] = records.map(r => {
      const typeLabel: string = r.type === 'income' ? '收入' : '支出';
      const escapedNote: string = r.note.includes(',') ?
        `"${r.note.replace(/"/g, '""')}"` : r.note;
      return `${r.date},${typeLabel},${r.category},${r.amount.toFixed(2)},${escapedNote}`;
    });
    return bom + header + '\n' + rows.join('\n');
  }

  /**
   * 将文本内容通过 DocumentViewPicker 保存到用户选择的目录
   * @returns true 表示保存成功
   */
  static async saveTextFile(
    context: common.UIAbilityContext,
    content: string,
    defaultName: string
  ): Promise<boolean> {
    try {
      // 写入沙箱临时文件
      const tmpPath: string = `${context.tempDir}/export_${Date.now()}_${defaultName}`;
      const tmpFile: fileIo.File = fileIo.openSync(tmpPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(tmpFile.fd, content);
      fileIo.closeSync(tmpFile);

      // 弹出保存选择器
      const saveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [defaultName];
      const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await docPicker.save(saveOptions);
      if (uris.length === 0) {
        fileIo.unlinkSync(tmpPath);
        return false;
      }

      // 复制临时文件到目标
      const destUri: string = uris[0];
      const srcFile: fileIo.File = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_ONLY);
      const destFile: fileIo.File = fileIo.openSync(destUri,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      const stat = fileIo.statSync(tmpPath);
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(srcFile.fd, buf);
      fileIo.writeSync(destFile.fd, buf);
      fileIo.closeSync(srcFile);
      fileIo.closeSync(destFile);
      fileIo.unlinkSync(tmpPath);
      return true;
    } catch (e) {
      console.error(`文件保存失败: ${JSON.stringify(e)}`);
      return false;
    }
  }
}
