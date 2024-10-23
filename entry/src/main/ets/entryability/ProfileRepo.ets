import { relationalStore, ValuesBucket } from '@kit.ArkData'
import { common } from '@kit.AbilityKit';



export function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

export enum ProfileType {
  File,
  Url,
  External
}

@Observed
export class Profile {
  uuid: string
  name: string
  type: ProfileType
  source: string = ""
  interval: number
  upload : number  =0
  download: number = 0
  total: number = 0
  expire: number = 0
  active: boolean
  createAt: number
  updatedAt: number

  constructor(type= ProfileType.Url) {
    this.uuid = generateUUID()
    this.name = "新配置"
    this.type = type // 0 url
    this.interval = 0
    this.active = false
    this.createAt = new Date().getTime()
    this.updatedAt = new Date().getTime()
  }
}

export class ProfileRepo{
  store: relationalStore.RdbStore | undefined
  constructor() {
  }
  async init(context: common.Context) {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'clash.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
    };
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG)
    this.initDb()
  }
  initDb() {
    try {
      const SQL_CREATE_TABLE = "CREATE TABLE IF NOT EXISTS Profiles(uuid TEXT PRIMARY KEY, name TEXT NOT NULL, type INTEGER NOT NULL, source TEXT, interval INTEGER, upload INTEGER, download INTEGER, total INTEGER, expire INTEGER, createAt INTEGER,active INTEGER,updatedAt INTEGER)"
      this.store?.executeSql(SQL_CREATE_TABLE); // 创建数据表
    } catch (e) {
      console.error(e)
    }
  }

  async delete(uuid: string) {
    const predicates = new relationalStore.RdbPredicates('Profiles')
    predicates.equalTo('uuid', uuid);
    await this.store!.delete(predicates);
  }
  async query(uuid: string | undefined) {
    if(uuid == undefined)
      return null
    const predicates = new relationalStore.RdbPredicates('Profiles')
    predicates.equalTo('uuid', uuid);
    const cursor = await this.store!.query(predicates);
    if (cursor.rowCount > 0) {
      cursor.goToNextRow();
      return this.getFromCursor(cursor);
    } else {
      return null;
    }
  }
  async queryAll(): Promise<Profile[]> {
    const predicates = new relationalStore.RdbPredicates('Profiles')
    const cursor = await this.store!.query(predicates)
    const list: Profile[] = []
    cursor.goToNextRow()
    while (cursor.rowIndex >= 0 && cursor.rowIndex < cursor.rowCount) {
      list.push(this.getFromCursor(cursor))
      cursor.goToNextRow()
    }
    return list;
  }

  async addOrUpdate(details: Profile) {
    const predicates = new relationalStore.RdbPredicates('Profiles')
    predicates.equalTo('uuid', details.uuid);
    const old = await this.store!.query(predicates)
    const input: ValuesBucket = {
      uuid: details.uuid,
      name: details.name,
      type: details.type,
      source: details.source,
      interval: details.interval,
      upload : details.upload,
      download: details.download,
      total: details.total,
      expire: details.expire,
      active: details.active ? 1: 0,
      createAt: details.createAt,
      updatedAt: details.updatedAt
    }
    if (old.rowCount > 0)
      this.store!.update(input, predicates)
    else
      this.store!.insert("Profiles", input)
  }

  getFromCursor(c: relationalStore.ResultSet): Profile {
    const details = new Profile();
    details.uuid = c.getString(0);
    details.name = c.getString(1);
    details.type = c.getLong(2);
    details.source = c.getString(3);
    details.interval = c.getLong(4);
    details.upload = c.getLong(5);
    details.download = c.getLong(6);
    details.total = c.getLong(7);
    details.expire = c.getLong(8);
    details.createAt = c.getLong(9);
    details.active = c.getLong(10) == 1
    details.updatedAt = c.getLong(11)
    return details;
  }
}