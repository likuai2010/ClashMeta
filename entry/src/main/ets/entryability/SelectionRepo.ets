import { relationalStore, ValuesBucket } from '@kit.ArkData'
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';


export  class Selection{
  uuid: string // profileId
  proxy: string = ""
  selected: string = ""
  constructor(uuid: string, proxy: string, selected: string) {
    this.uuid = uuid
    this.proxy = proxy
    this.selected = selected
  }
}


export class SelectionRepo{
  store: relationalStore.RdbStore | undefined
  constructor() {
  }
  async init(store: relationalStore.RdbStore | undefined) {
    this.store = store
    this.initDb()
  }
  initDb() {
    try {
      const SQL_CREATE_TABLE = "CREATE TABLE IF NOT EXISTS Selections(uuid TEXT PRIMARY KEY, proxy TEXT NOT NULL, selected TEXT NOT NULL)"
      this.store?.executeSql(SQL_CREATE_TABLE); // 创建数据表
    } catch (e) {
      promptAction.showToast({message:""})
      console.error(e)
    }
  }

  async delete(uuid: string) {
    const predicates = new relationalStore.RdbPredicates('Selections')
    predicates.equalTo('uuid', uuid);
    await this.store!.delete(predicates);
  }
  async query(uuid: string | undefined): Promise<Selection | null> {
    if(uuid == undefined)
      return null
    const predicates = new relationalStore.RdbPredicates('Selections')
    predicates.equalTo('uuid', uuid);
    const cursor = await this.store!.query(predicates);
    if (cursor.rowCount > 0 ) {
      cursor.goToNextRow();
      return this.getFromCursor(cursor);
    } else {
      return null;
    }
  }
  async queryAll(): Promise<Selection[]> {
    const predicates = new relationalStore.RdbPredicates('Selections')
    const cursor = await this.store!.query(predicates)
    const list: Selection[] = []
    cursor.goToNextRow()
    while (cursor.rowIndex >= 0 && cursor.rowIndex < cursor.rowCount) {
      list.push(this.getFromCursor(cursor))
      cursor.goToNextRow()
    }
    return list;
  }

  async addOrUpdate(details: Selection) {
    const predicates = new relationalStore.RdbPredicates('Selections')
    predicates.equalTo('uuid', details.uuid);
    const old = await this.store!.query(predicates)
    const input: ValuesBucket = {
      uuid: details.uuid,
      proxy: details.proxy,
      selected: details.selected,
    }
    if (old.rowCount > 0)
      this.store!.update(input, predicates)
    else
      this.store!.insert("Selections", input)
  }

  getFromCursor(c: relationalStore.ResultSet): Selection {
    const details = new Selection(c.getString(0),c.getString(1),c.getString(2));
    return details;
  }
}