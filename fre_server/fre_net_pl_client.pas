unit fre_net_pl_client;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$codepage UTF8}

interface

uses
  Classes, SysUtils,fre_system,fos_tool_interfaces,fre_aps_interface,fre_db_interface,fre_db_core;

  {TODO : Disallow Databases named "GLOBAL"}
type
  TFRE_DB_PL_NET_CLIENT=class;
  { TFRE_DB_PL_NET_CLIENT }

  TFRE_DB_PL_NET_CLIENT=class(TObject)
  private
  type
    TPL_CONN_CSTATE  = (sfc_NOT_CONNECTED,sfc_TRYING,sfc_NEGOTIATE_LAYER,sfc_OK,sfc_Failed);
    TPL_CMD_STATE    = (cs_READ_LEN,cs_READ_DATA);

    { TPLNet_Layer }
    TPLNet_Layer = class(IFRE_DB_PERSISTANCE_LAYER)
      FNETPL          : TFRE_DB_PL_NET_CLIENT;
      FId             : NativeInt;
      FConnectState   : TPL_CONN_CSTATE;
      FCMDState       : TPL_CMD_STATE;
      FLen            : Cardinal;
      FData           : Pointer;
      FSpecfile       : Shortstring;
      FLayername      : TFRE_DB_NameType;
      FIp             : Shortstring;
      FPort           : Shortstring;
      FHost           : ShortString;
      FChannel        : IFRE_APSC_CHANNEL;
      FConnLock       : IFOS_Lock;
      FCmdLock        : IFOS_LOCK;
      FLayerWait      : IFOS_E;
      FLasterror      : String;
      FLastErrorCode  : TFRE_DB_Errortype;
      FCommandPending : boolean;
      FGlobal         : boolean;
      FAnswer         : IFRE_DB_Object;
      FNotificationIF : IFRE_DB_DBChangedNotificationBlock;
      FCollections    : TList;
      constructor Create                     (nclient:TFRE_DB_PL_NET_CLIENT ; id:NativeInt ; host,ip,port,specfile,layername : Shortstring);
      destructor  Destroy                    ;override;
      procedure   LockLayer                  ;
      procedure   UnLockLayer                ;
      procedure   WaitForConnectStart        ;

      function    GetDboAsBufferLen          (const dbo: IFRE_DB_Object ; var mem : Pointer):UInt32;

      function    NewPersistenceLayerCommand (const cmdid: string) : IFRE_DB_Object;
      procedure   COR_SendDBO                (const Data : Pointer);
      function    SendCycle                  (const cmd : IFRE_DB_Object ; out answer : IFRE_DB_Object) : boolean;
      procedure   CheckRaiseAnswerError      (const answer : IFRE_DB_Object;const dont_raise : boolean=false);

      //function    _CollectionExists          (const coll_name: TFRE_DB_NameType; out Collection: IFRE_DB_PERSISTANCE_COLLECTION):Boolean;
      //function    _AddCollection             (const coll_name: TFRE_DB_NameType; const CollectionClassname: Shortstring; const isVolatile: boolean): IFRE_DB_PERSISTANCE_COLLECTION;
      //function    _RemoveCollection          (const coll_name: TFRE_DB_NameType):boolean;

      {PS Layer Interface }

      procedure DEBUG_DisconnectLayer         (const db:TFRE_DB_String);

      function  GetConnectedDB                : TFRE_DB_NameType;
      function  GetLastError                  : TFRE_DB_String;
      //function  GetCollection                 (const coll_name : TFRE_DB_NameType ; out Collection: IFRE_DB_PERSISTANCE_COLLECTION) : Boolean;

      function  Connect                       (const db_name:TFRE_DB_String ; out db_layer : IFRE_DB_PERSISTANCE_LAYER ;  const NotifIF : IFRE_DB_DBChangedNotificationBlock=nil) : TFRE_DB_Errortype;
      function  Disconnect                    : TFRE_DB_Errortype;

      function  DatabaseList                  : IFOS_STRINGS;
      function  DatabaseExists                (const dbname:TFRE_DB_String):Boolean;
      function  CreateDatabase                (const dbname:TFRE_DB_String):TFRE_DB_Errortype;
      function  DeleteDatabase                (const dbname:TFRE_DB_String):TFRE_DB_Errortype;
      function  DeployDatabaseScheme          (const scheme:IFRE_DB_Object):TFRE_DB_Errortype;
      function  GetDatabaseScheme             (out   scheme:IFRE_DB_Object):TFRE_DB_Errortype;
      procedure Finalize                      ;

      function  GetReferences                 (const obj_uid:TFRE_DB_GUID;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType='' ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_GUIDArray;
      function  GetReferencesCount            (const obj_uid:TFRE_DB_GUID;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType='' ; const user_context : PFRE_DB_GUID=nil):NativeInt;
      function  GetReferencesDetailed         (const obj_uid:TFRE_DB_GUID;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType='' ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_ObjectReferences;

      function  StartTransaction              (const typ:TFRE_DB_TRANSACTION_TYPE ; const ID:TFRE_DB_NameType) : TFRE_DB_Errortype;
      function  Commit                        : boolean;
      procedure RollBack                      ;
      function  RebuildUserToken              (const user_uid : TFRE_DB_GUID):IFRE_DB_USER_RIGHT_TOKEN;


      function  ObjectExists                  (const obj_uid : TFRE_DB_GUID) : boolean;
      function  DeleteObject                  (const obj_uid : TFRE_DB_GUID  ; const collection_name: TFRE_DB_NameType = '' ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_TransStepId;
      function  Fetch                         (const ouid   :  TFRE_DB_GUID  ; out   dbo:IFRE_DB_Object ; const user_context : PFRE_DB_GUID=nil): TFRE_DB_Errortype; //Remove internal fetch
      function  BulkFetch                     (const obj_uids: TFRE_DB_GUIDArray ; out objects : IFRE_DB_ObjectArray ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_Errortype;
      function  StoreOrUpdateObject           (const obj : IFRE_DB_Object ; const collection_name : TFRE_DB_NameType ; const store : boolean ; const user_context : PFRE_DB_GUID=nil) : TFRE_DB_TransStepId;
      procedure SyncWriteWAL                  (const WALMem : TMemoryStream);
      procedure SyncSnapshot                  ;
      procedure DEBUG_InternalFunction        (const func:NativeInt);

      function  GetLastErrorCode              : TFRE_DB_Errortype;

      procedure WT_TransactionID              (const number:qword);
      procedure WT_StoreCollectionPersistent  (const coll:TFRE_DB_PERSISTANCE_COLLECTION_BASE);
      procedure WT_StoreObjectPersistent      (const obj: IFRE_DB_Object);
      procedure WT_DeleteCollectionPersistent (const collname : TFRE_DB_NameType);
      procedure WT_DeleteObjectPersistent     (const iobj:IFRE_DB_Object);
      function  INT_Fetch                     (const ouid    :  TFRE_DB_GUID  ; out   dbo:IFRE_DB_Object):boolean;
      function  WT_GetSysLayer                : IFRE_DB_PERSISTANCE_LAYER;

      function  FDB_GetObjectCount            (const coll:boolean; const SchemesFilter:TFRE_DB_StringArray=nil): Integer;
      procedure FDB_ForAllObjects             (const cb:IFRE_DB_ObjectIteratorBrk; const SchemesFilter:TFRE_DB_StringArray=nil);
      procedure FDB_ForAllColls               (const cb:IFRE_DB_Obj_Iterator);
      function  FDB_GetAllCollsNames          :TFRE_DB_NameTypeArray;
      procedure FDB_PrepareDBRestore          (const phase:integer);
      procedure FDB_SendObject                (const obj:IFRE_DB_Object);
      procedure FDB_SendCollection            (const obj:IFRE_DB_Object);
      function  FDB_TryGetIndexStream         (const collname : TFRE_DB_NameType ; const ix_name : TFRE_DB_Nametype ; out stream : TStream):boolean;

      { Collection Interface }
      function  CollectionExistCollection           (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : Boolean;
      function  CollectionExistsInCollection        (const coll_name: TFRE_DB_NameType ; const check_uid: TFRE_DB_GUID; const has_fetch_rights: boolean ; const user_context : PFRE_DB_GUID=nil): boolean;
      function  CollectionDeleteCollection          (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : TFRE_DB_TransStepId;
      function  CollectionNewCollection             (const coll_name: TFRE_DB_NameType ; const volatile_in_memory: boolean ; const user_context : PFRE_DB_GUID=nil): TFRE_DB_TransStepId;
      function  CollectionDefineIndexOnField        (const coll_name: TFRE_DB_NameType ; const FieldName   : TFRE_DB_NameType ; const FieldType : TFRE_DB_FIELDTYPE   ; const unique     : boolean;
                                                     const ignore_content_case: boolean ; const index_name : TFRE_DB_NameType ; const allow_null_value : boolean=true ; const unique_null_values: boolean=false ; const is_a_domain_index: boolean = false; const user_context : PFRE_DB_GUID=nil): TFRE_DB_TransStepId;
      function  CollectionDropIndex                 (const coll_name: TFRE_DB_NameType ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_TransStepId;
      function  CollectionGetIndexDefinition        (const coll_name: TFRE_DB_NameType ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_INDEX_DEF;
      function  CollectionGetAllIndexNames          (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : TFRE_DB_NameTypeArray;
      function  CollectionFetchInCollection         (const coll_name: TFRE_DB_NameType ; const check_uid: TFRE_DB_GUID ; out   dbo:IFRE_DB_Object ; const user_context : PFRE_DB_GUID=nil):TFRE_DB_Errortype;
      function  CollectionBulkFetch                 (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil): IFRE_DB_ObjectArray;
      function  CollectionBulkFetchUIDS             (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil): TFRE_DB_GUIDArray;
      procedure CollectionClearCollection           (const coll_name: TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil);
      function  CollectionIndexExists               (const coll_name: TFRE_DB_NameType ; const index_name   : TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil):boolean;
      function  CollectionGetIndexedValueCount      (const coll_name: TFRE_DB_NameType; const qry_val: IFRE_DB_Object; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID=nil): NativeInt;
      function  CollectionGetIndexedObjsFieldval    (const coll_name: TFRE_DB_NameType ; const qry_val : IFRE_DB_Object ; out objs : IFRE_DB_ObjectArray ; const index_must_be_full_unique : boolean ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : NativeInt;
      function  CollectionGetIndexedUidsFieldval    (const coll_name: TFRE_DB_NameType ; const qry_val : IFRE_DB_Object ; out objs : TFRE_DB_GUIDArray   ; const index_must_be_full_unique : boolean ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : NativeInt;
      function  CollectionRemoveIndexedUidsFieldval (const coll_name: TFRE_DB_NameType ; const qry_val : IFRE_DB_Object ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : NativeInt;
      function  CollectionGetIndexedObjsRange       (const coll_name: TFRE_DB_NameType ; const min,max : IFRE_DB_Object ; const ascending: boolean ; const max_count,skipfirst : NativeInt ; out objs : IFRE_DB_ObjectArray ; const min_val_is_a_prefix : boolean ; const index_name:TFRE_DB_NameType ; const user_context : PFRE_DB_GUID=nil) : NativeInt;
      function  CollectionGetFirstLastIdxCnt        (const coll_name: TFRE_DB_NameType ; const idx : Nativeint ; out obj : IFRE_DB_Object ; const user_context : PFRE_DB_GUID=nil) : NativeInt;

      function  GetNotificationRecordIF    : IFRE_DB_DBChangedNotification; { to record changes }
    end;
  var
    FLayers            : TList;
    FLayerLock         : IFOS_LOCK;
    FStateTimer        : IFRE_APSC_TIMER;
    FGlobalConnectIP   : string;
    FGlobalConnectHost : string;
    FGlobalConnectPort : string;
    FGlobalUnixSocket  : string;

    procedure   MyStateCheckTimer  (const TIM : IFRE_APSC_TIMER ; const flag1,flag2 : boolean); // Timout & CMD Arrived & Answer Arrived
    procedure   NewSocket          (const channel  : IFRE_APSC_CHANNEL ; const channel_event : TAPSC_ChannelState);
    procedure   ReadClientChannel  (const channel  : IFRE_APSC_CHANNEL);
    procedure   DiscoClientChannel (const channel  : IFRE_APSC_CHANNEL);
    procedure   NewDBOFromServer_Locked   (const pls : TPLNet_Layer ; const dbo : IFRE_DB_Object);
  public
    constructor Create;
    destructor  Destroy;override;
    procedure   SetConnectionDetails (const host,ip,port:string;const uxs:string);
    function    ConnectPLServer      (const name:TFRE_DB_NameType ; out conn_layer : IFRE_DB_PERSISTANCE_LAYER ; const NotifIF: IFRE_DB_DBChangedNotificationBlock):TFRE_DB_Errortype;
    function    SearchForLayer       (const db_name : TFRE_DB_NameType ; out database_layer : IFRE_DB_PERSISTANCE_LAYER):boolean;
  end;

  function Get_PersistanceLayer_PS_Net(const host,ip,port:string) : IFRE_DB_PERSISTANCE_LAYER;

implementation

var GNET : TFRE_DB_PL_NET_CLIENT;
    GLAY : IFRE_DB_PERSISTANCE_LAYER;

function Get_PersistanceLayer_PS_Net(const host, ip, port: string): IFRE_DB_PERSISTANCE_LAYER;
var res : TFRE_DB_Errortype;
begin
  GNET := TFRE_DB_PL_NET_CLIENT.Create;
  GNET.SetConnectionDetails(host,ip,port,cFRE_PS_LAYER_UXSOCK_NAME);
  res := GNET.ConnectPLServer('GLOBAL',GLAY,nil);
  if res<>edb_OK then
    raise EFRE_DB_Exception.Create(edb_ERROR,res.Msg);
  result := GLAY;
end;


//{ TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection }
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetFirstLastIdx(const mode: NativeInt; const index: UInt64): IFRE_DB_Object;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//    res        : boolean;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFILAIX');
//  cmd.Field('T').AsInt32:=mode; { 0 = first, 1=last, 2= idx }
//  if mode=2 then
//    cmd.Field('IX').AsUint64 := index;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    res := answer.Field('A').AsBoolean;
//    if res then
//      result := answer.Field('O').CheckOutObject
//    else
//      result := nil;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//constructor TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Create(const collname: TFRE_DB_NameType; const CollectionClassname: Shortstring; const isVolatile: Boolean; const layer: TPLNet_Layer);
//begin
//  FName       := collname;
//  FUppername  := uppercase(FName);
//  FIsVolatile := isVolatile;
//  FCollClassn := CollectionClassname;
//  Flayer      := layer;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.SendCycleColl(const cmd: IFRE_DB_Object; out answer: IFRE_DB_Object): boolean;
//begin
//  cmd.Field('CN').AsString:=FName;
//  result := Flayer.SendCycle(cmd,answer);
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetPersLayerIntf: IFRE_DB_PERSISTANCE_COLLECTION_4_PERISTANCE_LAYER;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetPersLayer: IFRE_DB_PERSISTANCE_LAYER;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetCollectionClassName: ShortString;
//begin
//  result := FCollClassn;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.IsVolatile: boolean;
//begin
//  result := FIsVolatile;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.CollectionName(const unique: boolean): TFRE_DB_NameType;
//begin
//  if unique then
//    result := FUppername
//  else
//    result := FName;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Count: int64;
//var cmd,answer : IFRE_DB_Object;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGC');
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result := answer.Field('C').AsInt64;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Exists(const ouid: TFRE_DB_GUID): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CE');
//  cmd.Field('G').AsGUID:=ouid;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result := answer.Field('A').AsBoolean;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetAllUIDS(var uids: TFRE_DB_GUIDArray);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGAU');
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    uids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetAllObjects(var objs: IFRE_DB_ObjectArray);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGAO');
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    objs := answer.Field('O').AsObjectArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Fetch(const uid: TFRE_DB_GUID; var obj: IFRE_DB_Object): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CF');
//  cmd.Field('G').AsGUID:=uid;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result := answer.Field('A').AsBoolean;
//    if result then
//      obj := answer.Field('O').CheckOutObject
//    else
//      obj := nil;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.First: IFRE_DB_Object;
//begin
//  result := GetFirstLastIdx(0);
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Last: IFRE_DB_Object;
//begin
//  result := GetFirstLastIdx(1);
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetItem(const num: uint64): IFRE_DB_Object;
//begin
//  result := GetFirstLastIdx(2,num);
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.DefineIndexOnField(const FieldName: TFRE_DB_NameType; const FieldType: TFRE_DB_FIELDTYPE; const unique: boolean; const ignore_content_case: boolean; const index_name: TFRE_DB_NameType; const allow_null_value: boolean; const unique_null_values: boolean): TFRE_DB_Errortype;
//begin
//  //FLayer.DefineIndexOnField(self.CollectionName(false),FieldName,FieldType,unique,ignore_content_case,index_name,allow_null_value,unique_null_values);
//  //result := edb_OK;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedObj(const query_value: TFRE_DB_String; out obj: IFRE_DB_Object; const index_name: TFRE_DB_NameType ; const val_is_null : boolean = false): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGIO');
//  cmd.Field('Q').AsString  := query_value;
//  cmd.Field('IN').AsString := index_name;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result         := answer.Field('A').AsBoolean;
//    if result then
//      obj  := answer.Field('O').CheckOutObject;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedObj(const query_value: TFRE_DB_String; out obj: IFRE_DB_ObjectArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean ; const val_is_null : boolean = false): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGIOS');
//  cmd.Field('Q').AsString  := query_value;
//  cmd.Field('IN').AsString := index_name;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result         := answer.Field('A').AsBoolean;
//    obj            := answer.Field('O').CheckOutObjectArray;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUID(const query_value: TFRE_DB_String; out obj_uid: TFRE_DB_GUID; const index_name: TFRE_DB_NameType ; const val_is_null : boolean = false): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGIU');
//  cmd.Field('Q').AsString  := query_value;
//  cmd.Field('IN').AsString := index_name;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result         := answer.Field('A').AsBoolean;
//    obj_uid        := answer.Field('G').AsGUID;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUID(const query_value: TFRE_DB_String; out obj_uid: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean ; const val_is_null : boolean = false): boolean;
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CGIUS');
//  cmd.Field('Q').AsString    := query_value;
//  cmd.Field('IN').AsString   := index_name;
//  cmd.Field('CIU').AsBoolean := check_is_unique;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    result         := answer.Field('A').AsBoolean;
//    obj_uid        := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDSigned(const query_value: int64; out obj_uid: TFRE_DB_GUID; const index_name: TFRE_DB_NameType; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDUnsigned(const query_value: QWord; out obj_uid: TFRE_DB_GUID; const index_name: TFRE_DB_NameType; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDReal(const query_value: Double; out obj_uid: TFRE_DB_GUID; const index_name: TFRE_DB_NameType; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDSigned(const query_value: int64; out obj_uid: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDUnsigned(const query_value: QWord; out obj_uid: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.GetIndexedUIDReal(const query_value: Double; out obj_uid: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexed(var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFAI');
//  cmd.Field('IN').AsString := index_name;
//  cmd.Field('A').AsBoolean := ascending;
//  cmd.Field('M').AsInt64   := max_count;
//  cmd.Field('S').AsInt64   := skipfirst;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    guids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.IndexExists(const idx_name: TFRE_DB_NameType): NativeInt;
//begin
//  abort;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexedSignedRange(const min_value, max_value: int64; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFAISR');
//  cmd.Field('IN').AsString  := index_name;
//  cmd.Field('MIV').AsInt64  := min_value;
//  cmd.Field('MAV').AsInt64  := max_value;
//  cmd.Field('A').AsBoolean  := ascending;
//  cmd.Field('MN').AsBoolean := min_is_null;
//  cmd.Field('MM').AsBoolean := max_is_max;
//  cmd.Field('M').AsInt64    := max_count;
//  cmd.Field('S').AsInt64    := skipfirst;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    guids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexedUnsignedRange(const min_value, max_value: QWord; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFAIUR');
//  cmd.Field('IN').AsString  := index_name;
//  cmd.Field('MIV').AsUInt64 := min_value;
//  cmd.Field('MAV').AsUInt64 := max_value;
//  cmd.Field('A').AsBoolean  := ascending;
//  cmd.Field('MN').AsBoolean := min_is_null;
//  cmd.Field('MM').AsBoolean := max_is_max;
//  cmd.Field('M').AsInt64    := max_count;
//  cmd.Field('S').AsInt64    := skipfirst;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    guids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexedRealRange(const min_value, max_value: Double; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//begin
//  abort;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexedStringRange(const min_value, max_value: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFAISS');
//  cmd.Field('IN').AsString  := index_name;
//  cmd.Field('MIV').AsString := min_value;
//  cmd.Field('MAV').AsString := max_value;
//  cmd.Field('A').AsBoolean  := ascending;
//  cmd.Field('MN').AsBoolean := min_is_null;
//  cmd.Field('MM').AsBoolean := max_is_max;
//  cmd.Field('M').AsInt64    := max_count;
//  cmd.Field('S').AsInt64    := skipfirst;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    guids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//procedure TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.ForAllIndexPrefixString(const prefix: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const max_count: NativeInt; skipfirst: NativeInt);
//var cmd,answer : IFRE_DB_Object;
//    dba        : TFRE_DB_StringArray;
//begin
//  cmd :=  Flayer.NewPersistenceLayerCommand('CFAIPS');
//  cmd.Field('IN').AsString  := index_name;
//  cmd.Field('MIV').AsString := prefix;
//  cmd.Field('A').AsBoolean  := ascending;
//  cmd.Field('M').AsInt64    := max_count;
//  cmd.Field('S').AsInt64    := skipfirst;
//  SendCycleColl(cmd,answer);
//  try
//    FLayer.CheckRaiseAnswerError(answer);
//    guids := answer.Field('G').AsGUIDArr;
//    Flayer.FLasterror     := '';
//    FLayer.FLastErrorCode := edb_OK;
//  finally
//    answer.Finalize;
//  end;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Remove(const ouid: TFRE_DB_GUID): TFRE_DB_Errortype;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.RemoveIndexedString(const query_value: TFRE_DB_String; const index_name: TFRE_DB_NameType ; const val_is_null : boolean = false): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.RemoveIndexedSigned(const query_value: int64; const index_name: TFRE_DB_NameType ; const val_is_null : boolean = false): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.RemoveIndexedUnsigned(const query_value: QWord; const index_name: TFRE_DB_NameType ; const val_is_null : boolean = false): boolean;
//begin
//  abort;
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.RemoveIndexedReal(const query_value: Double; const index_name: TFRE_DB_NameType; const val_is_null: boolean): boolean;
//begin
//  abort;
//end;

constructor TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Create(nclient: TFRE_DB_PL_NET_CLIENT; id: NativeInt; host, ip, port, specfile, layername: Shortstring);
begin
  Fid          := id;
  FIp          := ip;
  FPort        := port;
  FHost        := host;
  FSpecfile    := specfile;
  FLayername   := uppercase(layername);
  FGlobal      := FLayername='GLOBAL';
  FNETPL       := nclient;
  FCollections := TList.Create;
  GFRE_TF.Get_Lock(FConnLock);
  GFRE_TF.Get_Lock(FCmdLock);
  GFRE_TF.Get_Event(FLayerWait);
end;

destructor TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Destroy;
begin
  FConnLock.Finalize;
  FCmdlock.Finalize;
  FLayerWait.Finalize;
  FCollections.free;
  inherited Destroy;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.LockLayer;
begin
  FConnLock.Acquire;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.UnLockLayer;
begin
  FConnLock.Release;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WaitForConnectStart;
begin
  FLayerWait.WaitFor;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetDboAsBufferLen(const dbo: IFRE_DB_Object; var mem: Pointer): UInt32;
var len : UInt32;
    ns  : UInt32;
begin
  ns := dbo.NeededSize;
  Getmem(mem,ns+4);
  dbo.CopyToMemory(mem+4);
  PCardinal(mem)^:=ns;
  result := ns+4;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.NewPersistenceLayerCommand(const cmdid: string): IFRE_DB_Object;
begin
  result := GFRE_DBI.NewObject;
  result.Field('CID').AsString:=cmdid;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.COR_SendDBO(const Data: Pointer);
var cmd : IFRE_DB_Object;
    mem : pointer;
    siz : Cardinal;
begin
  cmd := TFRE_DB_Object(data);
  siz := GetDboAsBufferLen(cmd,mem);
  try
    cmd.Finalize;
    FChannel.CH_WriteBuffer(mem,siz);
  finally
    Freemem(mem);
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.SendCycle(const cmd: IFRE_DB_Object; out answer: IFRE_DB_Object): boolean;
begin
  FCmdLock.Acquire;
  try
    if FCommandPending=true then
      raise EFRE_DB_Exception.Create(edb_INTERNAL,'double send cycle!');
    FCommandPending := true;
    FChannel.GetChannelManager.ScheduleCoRoutine(@self.COR_SendDBO,cmd.Implementor);
    FLayerWait.WaitFor;
    answer := FAnswer;
    FAnswer:=nil;
    FCommandPending:=false;
  finally
    FCmdLock.Release;
  end;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CheckRaiseAnswerError(const answer: IFRE_DB_Object; const dont_raise: boolean);
var ec : TFRE_DB_Errortype_EC;
    es : String;
begin
  try
    ec := TFRE_DB_Errortype_EC(answer.Field('EC').AsInt16);
    es := answer.Field('ES').AsString;
    if (ord(ec)<ord(low(TFRE_DB_Errortype_EC))) or
        (ord(ec)>ord(High(TFRE_DB_Errortype_EC))) then
          begin
            FLastErrorCode := edb_INTERNAL;
            FLasterror     := es+' and the errorcode is out of bounds(!!)'+inttostr(ord(ec));
          end
  except
    on e:Exception do
      begin
        ec := edb_INTERNAL;
        es := 'CHECKERROR EXCEPTION '+e.Message+' '+es;
      end;
  end;
  FLasterror     := es;
  FLastErrorCode := ec;
  if (ec<>edb_OK) and
     (dont_raise=false) then
       raise EFRE_DB_Exception.Create(ec,es);
end;

//function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer._CollectionExists(const coll_name: TFRE_DB_NameType; out Collection: IFRE_DB_PERSISTANCE_COLLECTION): Boolean;
//var i   : NativeInt;
//    cnu : TFRE_DB_NameType;
//    cns : TFRE_DB_NameType;
//begin
//  cnu := UpperCase(coll_name);
//  for i := 0 to FCollections.Count-1 do
//    begin
//      cns := TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection(FCollections[i]).CollectionName(true);
//      if  cns=cnu then
//        begin
//          Collection := TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection(FCollections[i]);
//          exit(true);
//        end;
//    end;
//  exit(false);
//end;
//
//function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer._AddCollection(const coll_name: TFRE_DB_NameType; const CollectionClassname: Shortstring; const isVolatile: boolean): IFRE_DB_PERSISTANCE_COLLECTION;
//var x : TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection;
//begin
// if not _CollectionExists(coll_name,result) then
//   begin
//     x := TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection.Create(coll_name,CollectionClassname,isVolatile,self);
//     FCollections.Add(x);
//     result := x;
//   end;
//end;

//function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer._RemoveCollection(const coll_name: TFRE_DB_NameType): boolean;
//var i   : NativeInt;
//    cnu : TFRE_DB_NameType;
//    cns : TFRE_DB_NameType;
//      x : TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection;
//begin
//  cnu := UpperCase(coll_name);
//  for i := FCollections.Count-1 downto 0 do
//    begin
//      cns := TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection(FCollections[i]).CollectionName(true);
//      if  cns=cnu then
//        begin
//          x := TFRE_DB_PL_NET_CLIENT.TPLNet_PersistanceCollection(FCollections[i]);
//          x.Free;
//          FCollections.Delete(i);
//          exit(true);
//        end;
//    end;
//  exit(false);
//end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DEBUG_DisconnectLayer(const db: TFRE_DB_String);
begin
  ; // abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetConnectedDB: TFRE_DB_NameType;
begin
  result := FLayername;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetLastError: TFRE_DB_String;
//var cmd,answer : IFRE_DB_Object;
//    s          : string;
begin
  result := FLasterror;   {Get's set on every cmd execution as answer from partner}
  //cmd := NewPersistenceLayerCommand('GLE');
  //SendCycle(cmd,answer);
  //try
  //  CheckRaiseAnswerError(answer);
  //  FLasterror := answer.Field('A').AsString;
  //  result     := FLasterror;
  //finally
  //  answer.Finalize;
  //end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionExistCollection(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): Boolean;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer')
  else
    begin
      cmd := NewPersistenceLayerCommand('EC');
      cmd.Field('CN').AsString:=coll_name;
      SendCycle(cmd,answer);
      try
        CheckRaiseAnswerError(answer);
        result := answer.Field('A').AsBoolean;
        //if result then
        //  _AddCollection(coll_name,answer.Field('CCN').AsString,answer.Field('V').AsBoolean);
        FLasterror     := '';
        FLastErrorCode := edb_OK;
      finally
        answer.Finalize;
      end;
    end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionExistsInCollection(const coll_name: TFRE_DB_NameType; const check_uid: TFRE_DB_GUID; const has_fetch_rights: boolean; const user_context: PFRE_DB_GUID): boolean;
begin
  abort;
end;

//function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetCollection(const coll_name: TFRE_DB_NameType; out Collection: IFRE_DB_PERSISTANCE_COLLECTION): Boolean;
//begin
//  if FGlobal then
//    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer')
//  else
//    result := CollectionExistCollection(coll_name);
//end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionNewCollection(const coll_name: TFRE_DB_NameType; const volatile_in_memory: boolean; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  begin
    cmd := NewPersistenceLayerCommand('NC');
    cmd.Field('cn').AsString:=coll_name;
    cmd.Field('v').AsBoolean:=volatile_in_memory;
    SendCycle(cmd,answer);
    try
      CheckRaiseAnswerError(answer);
      result := answer.Field('TSID').AsString;
      FLasterror     := '';
      FLastErrorCode := edb_OK;
      abort;
      //Collection := _AddCollection(coll_name,CollectionClassname,volatile_in_memory);
    finally
      answer.Finalize;
    end;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionFetchInCollection(const coll_name: TFRE_DB_NameType; const check_uid: TFRE_DB_GUID; out dbo: IFRE_DB_Object; const user_context: PFRE_DB_GUID): TFRE_DB_Errortype;
begin

end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_TransactionID(const number: qword);
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionDeleteCollection(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  begin
    cmd := NewPersistenceLayerCommand('DC');
    cmd.Field('cn').AsString:=coll_name;
    SendCycle(cmd,answer);
    try
      CheckRaiseAnswerError(answer);
      result := answer.Field('TSID').AsString;
      FLasterror     := '';
      FLastErrorCode := edb_OK;
      //_RemoveCollection(coll_name);
    finally
      answer.Finalize;
    end;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Connect(const db_name: TFRE_DB_String; out db_layer: IFRE_DB_PERSISTANCE_LAYER ; const NotifIF: IFRE_DB_DBChangedNotificationBlock): TFRE_DB_Errortype;
begin
  if not FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is only allowed in then global layer');
  if FNETPL.SearchForLayer(db_name,db_layer) then
    exit(edb_OK);
  result := FNETPL.ConnectPLServer(db_name,db_layer,NotifIF);
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Disconnect: TFRE_DB_Errortype;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_ERROR,'the global layer cannot be disconnected')
  else
    begin
      if assigned(FNotificationIF) then
        begin
          //FNotificationIF.FinalizeNotif;
          FNotificationIF:=nil;
        end;
    end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DatabaseList: IFOS_STRINGS;
var cmd,answer : IFRE_DB_Object;
    dba        : TFRE_DB_StringArray;
    i          : NativeInt;
begin
  cmd := NewPersistenceLayerCommand('DL');
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer);
    dba := answer.Field('A').AsStringArr;
    result := GFRE_TF.Get_FOS_Strings;
    for i:=0 to high(dba) do
      begin
        result.Add(dba[i]);
      end;
    FLasterror     := '';
    FLastErrorCode := edb_OK;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DatabaseExists(const dbname: TFRE_DB_String): Boolean;
var cmd,answer : IFRE_DB_Object;
begin
  cmd := NewPersistenceLayerCommand('DE');
  cmd.Field('DB').AsString:=dbname;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer);
    result := answer.Field('A').AsBoolean;
    FLasterror     := '';
    FLastErrorCode := edb_OK;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CreateDatabase(const dbname: TFRE_DB_String): TFRE_DB_Errortype;
var cmd,answer : IFRE_DB_Object;
begin
  cmd := NewPersistenceLayerCommand('CD');
  cmd.Field('DB').AsString:=dbname;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,true);
    result := FLastErrorCode;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DeleteDatabase(const dbname: TFRE_DB_String): TFRE_DB_Errortype;
var cmd,answer : IFRE_DB_Object;
begin
  cmd := NewPersistenceLayerCommand('DD');
  cmd.Field('DB').AsString:=dbname;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,true);
    result := FLastErrorCode;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DeployDatabaseScheme(const scheme: IFRE_DB_Object): TFRE_DB_Errortype;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetDatabaseScheme(out scheme: IFRE_DB_Object): TFRE_DB_Errortype;
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Finalize;
begin
//  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetReferences(const obj_uid: TFRE_DB_GUID; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_GUIDArray;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('GR');
  cmd.Field('G').AsGUID    := obj_uid;
  cmd.Field('F').AsBoolean := from;
  cmd.Field('SP').AsString := scheme_prefix_filter;
  cmd.Field('FE').AsString := field_exact_filter;
  SendCycle(cmd,answer);
  try
    result := nil;
    CheckRaiseAnswerError(answer);
    result := answer.Field('G').AsGUIDArr;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetReferencesCount(const obj_uid: TFRE_DB_GUID; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('GRC');
  cmd.Field('G').AsGUID    := obj_uid;
  cmd.Field('F').AsBoolean := from;
  cmd.Field('SP').AsString := scheme_prefix_filter;
  cmd.Field('FE').AsString := field_exact_filter;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer);
    result := answer.Field('C').AsInt64;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetReferencesDetailed(const obj_uid: TFRE_DB_GUID; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_ObjectReferences;
var cmd,answer : IFRE_DB_Object;
    i          : NativeInt;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('GRD');
  cmd.Field('G').AsGUID    := obj_uid;
  cmd.Field('F').AsBoolean := from;
  cmd.Field('SP').AsString := scheme_prefix_filter;
  cmd.Field('FE').AsString := field_exact_filter;
  SendCycle(cmd,answer);
  try
    result := nil;
    CheckRaiseAnswerError(answer);
    SetLength(result,length(answer.Field('FN').AsStringArr));
    for i:=0 to high(result) do
      with Result[i] do
        begin
          fieldname  := answer.Field('FN').AsStringArr[i];
          schemename := answer.Field('SN').AsStringArr[i];
          linked_uid := answer.Field('LU').AsGUIDArr[i];
        end;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.StartTransaction(const typ: TFRE_DB_TRANSACTION_TYPE; const ID: TFRE_DB_NameType): TFRE_DB_Errortype;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Commit: boolean;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.RollBack;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.RebuildUserToken(const user_uid: TFRE_DB_GUID): IFRE_DB_USER_RIGHT_TOKEN;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.ObjectExists(const obj_uid: TFRE_DB_GUID): boolean;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('E');
  cmd.Field('G').AsGUID    := obj_uid;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,false);
    result := answer.Field('E').AsBoolean;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DeleteObject(const obj_uid: TFRE_DB_GUID; const collection_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('D');
  cmd.Field('G').AsGUID    := obj_uid;
  cmd.Field('CN').AsString := collection_name;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,false);
    result := answer.Field('TSID').AsString;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.Fetch(const ouid: TFRE_DB_GUID; out dbo: IFRE_DB_Object; const user_context: PFRE_DB_GUID): TFRE_DB_Errortype;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('F');
  cmd.Field('G').AsGUID    := ouid;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,true);
    result         := FLastErrorCode;
    if result=edb_OK then
      dbo := answer.Field('O').CheckOutObject
    else
      dbo := nil;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.BulkFetch(const obj_uids: TFRE_DB_GUIDArray; out objects: IFRE_DB_ObjectArray; const user_context: PFRE_DB_GUID): TFRE_DB_Errortype;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('BF');
  cmd.Field('G').AsGUIDArr := obj_uids;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer,true);
    result         := FLastErrorCode;
    if result=edb_OK then
      objects := answer.Field('O').CheckOutObjectArray
    else
      objects := nil;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.StoreOrUpdateObject(const obj: IFRE_DB_Object; const collection_name: TFRE_DB_NameType; const store: boolean; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
var cmd,answer : IFRE_DB_Object;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('SOU');
  cmd.Field('CN').AsString := collection_name;
  cmd.Field('O').AsObject  := obj;
  cmd.Field('S').AsBoolean := store;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer);
    result         := answer.Field('TSID').AsString;
    FLasterror     := '';
    FLastErrorCode := edb_OK;
  finally
    answer.Finalize;
  end;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.SyncWriteWAL(const WALMem: TMemoryStream);
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.SyncSnapshot;
begin
  ; { Silent ignore, until WAL Mode is implemented }
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.DEBUG_InternalFunction(const func: NativeInt);
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionDefineIndexOnField(const coll_name: TFRE_DB_NameType; const FieldName: TFRE_DB_NameType; const FieldType: TFRE_DB_FIELDTYPE; const unique: boolean; const ignore_content_case: boolean; const index_name: TFRE_DB_NameType; const allow_null_value: boolean; const unique_null_values: boolean; const is_a_domain_index: boolean; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
var cmd,answer : IFRE_DB_Object;
    dba        : TFRE_DB_StringArray;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  cmd := NewPersistenceLayerCommand('DIF');
  cmd.Field('CN').AsString:=coll_name;
  cmd.Field('FN').AsString:=FieldName;
  cmd.Field('FT').AsString:=CFRE_DB_FIELDTYPE_SHORT[FieldType];
  cmd.Field('U').AsBoolean:=unique;
  cmd.Field('CC').AsBoolean:=ignore_content_case;
  cmd.Field('IN').AsString:=index_name;
  cmd.Field('AN').AsBoolean:=allow_null_value;
  cmd.Field('UN').AsBoolean:=unique_null_values;
  cmd.Field('DI').AsBoolean:=is_a_domain_index;
  SendCycle(cmd,answer);
  try
    CheckRaiseAnswerError(answer);
    result         := answer.Field('TSID').AsString;
    FLasterror     := '';
    FLastErrorCode := edb_OK;
  finally
    answer.Finalize;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionDropIndex(const coll_name: TFRE_DB_NameType; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_TransStepId;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetIndexDefinition(const coll_name: TFRE_DB_NameType; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_INDEX_DEF;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetAllIndexNames(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_NameTypeArray;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetLastErrorCode: TFRE_DB_Errortype;
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  result := FLastErrorCode;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_StoreCollectionPersistent(const coll: TFRE_DB_PERSISTANCE_COLLECTION_BASE);
begin
  if FGlobal then
    raise EFRE_DB_Exception.Create(edb_PERSISTANCE_ERROR,'operation is not allowed in then global layer');
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_StoreObjectPersistent(const obj: IFRE_DB_Object);
begin

end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_DeleteCollectionPersistent(const collname: TFRE_DB_NameType);
begin

end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_DeleteObjectPersistent(const iobj: IFRE_DB_Object);
begin

end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.INT_Fetch(const ouid: TFRE_DB_GUID; out dbo: IFRE_DB_Object): boolean;
begin
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.WT_GetSysLayer: IFRE_DB_PERSISTANCE_LAYER;
begin
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_GetObjectCount(const coll: boolean; const SchemesFilter: TFRE_DB_StringArray): Integer;
begin
  abort;
end;


procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_ForAllObjects(const cb: IFRE_DB_ObjectIteratorBrk; const SchemesFilter: TFRE_DB_StringArray);
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_ForAllColls(const cb: IFRE_DB_Obj_Iterator);
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_GetAllCollsNames: TFRE_DB_NameTypeArray;
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_PrepareDBRestore(const phase: integer);
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_SendObject(const obj: IFRE_DB_Object);
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_SendCollection(const obj: IFRE_DB_Object);
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.FDB_TryGetIndexStream(const collname: TFRE_DB_NameType; const ix_name: TFRE_DB_Nametype; out stream: TStream): boolean;
begin
  abort;
end;


function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionBulkFetch(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): IFRE_DB_ObjectArray;
begin
  aborT;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionBulkFetchUIDS(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): TFRE_DB_GUIDArray;
begin
  abort;
end;

procedure TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionClearCollection(const coll_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID);
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionIndexExists(const coll_name: TFRE_DB_NameType; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): boolean;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetIndexedValueCount(const coll_name: TFRE_DB_NameType; const qry_val: IFRE_DB_Object; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetIndexedObjsFieldval(const coll_name: TFRE_DB_NameType; const qry_val: IFRE_DB_Object; out objs: IFRE_DB_ObjectArray; const index_must_be_full_unique: boolean; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetIndexedUidsFieldval(const coll_name: TFRE_DB_NameType; const qry_val: IFRE_DB_Object; out objs: TFRE_DB_GUIDArray; const index_must_be_full_unique: boolean; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionRemoveIndexedUidsFieldval(const coll_name: TFRE_DB_NameType; const qry_val: IFRE_DB_Object; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetIndexedObjsRange(const coll_name: TFRE_DB_NameType; const min, max: IFRE_DB_Object; const ascending: boolean; const max_count, skipfirst: NativeInt; out objs: IFRE_DB_ObjectArray; const min_val_is_a_prefix: boolean; const index_name: TFRE_DB_NameType; const user_context: PFRE_DB_GUID): NativeInt;
begin
  aborT;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.CollectionGetFirstLastIdxCnt(const coll_name: TFRE_DB_NameType; const idx: Nativeint; out obj: IFRE_DB_Object; const user_context: PFRE_DB_GUID): NativeInt;
begin
  abort;
end;

function TFRE_DB_PL_NET_CLIENT.TPLNet_Layer.GetNotificationRecordIF: IFRE_DB_DBChangedNotification;
begin
  raise EFRE_DB_Exception.Create(edb_INTERNAL,'the net layer is not supposed to record changes');
end;

{ TFRE_DB_PL_NET_CLIENT.TPLNet_Layer }

procedure TFRE_DB_PL_NET_CLIENT.NewSocket(const channel: IFRE_APSC_CHANNEL; const channel_event: TAPSC_ChannelState);
var layr : TPLNet_Layer;
    id   : NativeInt;
begin
  if channel_event=ch_NEW_CS_CONNECTED then
    begin
      FLayerlock.Acquire;
      try
        id   := StrToInt(channel.CH_GetID);
        layr := TPLNet_Layer(FLayers[id]);
        layr.FConnectState := sfc_NEGOTIATE_LAYER;
        layr.FCMDState     := cs_READ_LEN;
        channel.CH_AssociateData(FREDB_ObjectToPtrUInt(layr));
        channel.CH_WriteString(layr.FLayername);
        channel.CH_Enable_Reading;
      finally
        FLayerLock.Release;
      end;
    end
  else
    begin
      channel.Finalize;
    end;
end;

procedure TFRE_DB_PL_NET_CLIENT.ReadClientChannel(const channel: IFRE_APSC_CHANNEL);
var layr  : TPLNet_Layer;
    id    : NativeInt;

    procedure _FetchDBO;
    var
        len   : cardinal;
        fcont : boolean;
        dbo   : IFRE_DB_Object;
    begin
      repeat
        fcont := false;
        case layr.FCMDState of
          cs_READ_LEN:
            begin
              if channel.CH_GetDataCount>=4 then
                begin
                  channel.CH_ReadBuffer(@layr.FLen,4);
                  fcont := true;
                  getmem(layr.FData,layr.FLen);
                  layr.FCMDState:=cs_READ_DATA;
                end;
            end;
          cs_READ_DATA:
            begin
              if channel.CH_GetDataCount>=layr.FLen then
                begin
                  channel.CH_ReadBuffer(layr.FData,layr.FLen);
                  fcont := true;
                  try
                    try
                      dbo := GFRE_DBI.CreateFromMemory(layr.FData);
                      try
                        NewDBOFromServer_Locked(layr,dbo);
                      except on e:exception do
                        begin
                          GFRE_DBI.LogError(dblc_PERSISTANCE,'FAILURE INBOUND EVENT PROCESSING [%s]',[e.Message]);
                        end;
                      end;
                    finally
                      Freemem(layr.FData);
                      layr.FData:=nil;
                    end;
                  except on e:exception do
                    begin
                      writeln('SUB CHANNEL READ FAILED ',e.Message);
                      channel.Finalize;
                      layr.FConnectState := sfc_NOT_CONNECTED;
                    end;
                  end;
                  layr.FCMDState := cs_READ_LEN;
                end;
            end;
        end;
      until fcont=false;
    end;

    procedure _NegotiateLayerAnswer;
    var answer:string;
    begin
      answer := channel.CH_ReadString;
      if answer='OK' then
        begin
          layr.FConnectState := sfc_OK;
          layr.FChannel:=channel;
          layr.FLayerWait.SetEvent;
        end
      else
        begin
          channel.Finalize;
          layr.FConnectState := sfc_Failed;
          layr.FLayerWait.SetEvent;
        end;
    end;

begin
  layr := FREDB_PtrUIntToObject(channel.CH_GetAssociateData) as TPLNet_Layer;
  layr.LockLayer;
  try
    case layr.FConnectState of
      sfc_NOT_CONNECTED,sfc_TRYING:
        GFRE_BT.CriticalAbort('invalid state, read clientchannel '+IntToStr(ord(layr.FConnectState)));
      sfc_NEGOTIATE_LAYER:
        _NegotiateLayerAnswer;
      sfc_OK:
        _FetchDBO;
    end;
  finally
    layr.UnLockLayer;
  end;
end;

procedure TFRE_DB_PL_NET_CLIENT.DiscoClientChannel(const channel: IFRE_APSC_CHANNEL);
var layr : TPLNet_Layer;
begin
  layr := TPLNet_Layer(FLayers[strtoint(channel.CH_GetID)]);
  if assigned(layr) then
    begin
      layr.LockLayer;
      try
        case layr.FConnectState of
          sfc_TRYING:
            begin {Disconnect in trying = connection refused}
              layr.FLasterror := 'CONNECTION REFUSED';
              layr.FConnectState:=sfc_Failed;
              layr.FLayerWait.SetEvent;
            end;
          sfc_NOT_CONNECTED: ;
            //GFRE_BT.CriticalAbort('invalid state, read clientchannel '+IntToStr(ord(layr.FConnectState)));
          sfc_NEGOTIATE_LAYER: ;
            //_NegotiateLayerAnswer;
          sfc_OK: ;
        end;
      finally
        layr.UnLockLayer;
      end;
    end;
end;

procedure TFRE_DB_PL_NET_CLIENT.NewDBOFromServer_Locked(const pls: TPLNet_Layer; const dbo: IFRE_DB_Object);
begin
  if dbo.Field('CID').AsString='EVENT' then {Process Event}
    begin
      if assigned(pls.FNotificationIF) then
        try
          pls.FNotificationIF.SendNotificationBlock(dbo.Field('BLOCK').AsObject);
        except on e:exception do
          GFRE_DBI.LogError(dblc_PERSISTANCE,'FAILURE INBOUND EVENT PROCESSING NOTIFY [%s]',[e.Message]);
        end;
    end
  else
    begin {It's an answer}
      if pls.FCommandPending=false then
        raise EFRE_DB_Exception.Create(edb_INTERNAL,'sequencing error cmd not pending!');
      pls.FAnswer := dbo;
      pls.FLayerWait.SetEvent;
    end;
end;

{ TFRE_DB_PL_NET_CLIENT }

procedure TFRE_DB_PL_NET_CLIENT.MyStateCheckTimer(const TIM: IFRE_APSC_TIMER; const flag1, flag2: boolean);
var i : NativeInt;
begin
  FLayerLock.Acquire;
  try
    if (flag1=false) and (flag2=false) then
      for i := 0 to FLayers.Count-1 do
        with TPLNet_Layer(FLayers[i]) do
          case FConnectState of
            sfc_NOT_CONNECTED:
              begin // Start a client
                try
                  FConnectState:=sfc_TRYING;
                  if FSpecfile<>'' then
                    GFRE_SC.AddClient_UX(FSpecfile,inttostr(i),nil,@NewSocket,@ReadClientChannel,@DiscoClientChannel)
                  else
                    if FHost<>'' then
                      GFRE_SC.AddClient_TCP_DNS(FHost,FPort,inttostr(i),nil,@NewSocket,@ReadClientChannel,@DiscoClientChannel)
                    else
                      GFRE_SC.AddClient_TCP(FIp,FPort,inttostr(i),nil,@NewSocket,@ReadClientChannel,@DiscoClientChannel)
                except
                  on E:Exception do
                  begin
                    FLasterror    := 'CONNECTION CRITICAL:'+e.Message;
                    FConnectState := sfc_Failed;
                    FLayerWait.SetEvent;
                  end;
                end;
              end;
            sfc_TRYING: ; // do nothing
            sfc_OK: ; // do nothing
          end;
  finally
    FLayerLock.Release;
  end;
end;

constructor TFRE_DB_PL_NET_CLIENT.Create;
begin
  FLayers     := TList.Create;
  GFRE_TF.Get_Lock(FLayerLock);
  FStateTimer := GFRE_SC.AddTimer('CS',1000,@MyStateCheckTimer);
end;

destructor TFRE_DB_PL_NET_CLIENT.Destroy;
begin
  FLayers.free;
  FLayerLock.Finalize;
  inherited Destroy;
end;

procedure TFRE_DB_PL_NET_CLIENT.SetConnectionDetails(const host, ip, port: string; const uxs: string);
begin
  FGlobalConnectHost := host;
  FGlobalConnectIP   := Ip;
  FGlobalConnectPort := port;
  FGlobalUnixSocket  := cFRE_UX_SOCKS_DIR+uxs;
end;

function TFRE_DB_PL_NET_CLIENT.ConnectPLServer(const name: TFRE_DB_NameType; out conn_layer: IFRE_DB_PERSISTANCE_LAYER; const NotifIF: IFRE_DB_DBChangedNotificationBlock): TFRE_DB_Errortype;
var lay : TPLNet_Layer;
begin
  FLayerLock.Acquire;
  try
    lay := TPLNet_Layer.Create(self,FLayers.Count,FGlobalConnectHost,FGlobalConnectIP,FGlobalConnectPort,FGlobalUnixSocket,name);
    FLayers.Add(lay);
    lay.FNotificationIF := NotifIF;
  finally
    FLayerLock.Release;
  end;
  conn_layer := lay;
  FStateTimer.TIM_Trigger;
  lay.WaitForConnectStart;
  case lay.FConnectState of
    sfc_OK:
      begin
        result.Code  := edb_OK;
        result.Msg   := lay.FLasterror;
      end;
    sfc_Failed:
      begin
        result.Code  := edb_ERROR;
        result.Msg   := lay.FLasterror;
      end
    else
      begin
        result.Code := edb_INTERNAL;
        result.Msg   := lay.FLasterror;
      end;
  end;
end;

function TFRE_DB_PL_NET_CLIENT.SearchForLayer(const db_name: TFRE_DB_NameType; out database_layer: IFRE_DB_PERSISTANCE_LAYER): boolean;
var i : NativeInt;
begin
  result := false;
  FLayerLock.Acquire;
  try
    for i := 0 to FLayers.count-1 do
      if uppercase(TPLNet_Layer(FLayers[i]).FLayername)=uppercase(db_name) then
        begin
          database_layer := TPLNet_Layer(FLayers[i]);
          result         := true;
        end;
    database_layer := nil;
    result := false;
  finally
    FLayerLock.Release;
  end;
end;


end.

