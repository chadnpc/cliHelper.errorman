#!/usr/bin/env pwsh
#Requires -Modules devconstants

#region    Classes
class ErrorMetadata {
  [bool]$IsPrinted = $false
  [datetime]$Timestamp
  [string]$ErrorMessage
  [string]$StackTrace
  [string]$ErrorCode
  [string]$Severity
  [string]$User
  [string]$Module
  [string]$Function
  [string]$AdditionalInfo

  ErrorMetadata() {}
  ErrorMetadata([hashtable]$obj) {
    $obj.Keys.ForEach({
        if ($null -ne $obj.$_) {
          $this.$_ = $obj.$_
        }
      }
    )
  }
  ErrorMetadata([bool]$IsPrinted) { $this.IsPrinted = $IsPrinted }
  ErrorMetadata([bool]$IsPrinted, [datetime]$Timestamp, [string]$ErrorMessage) {
    $this.IsPrinted = $IsPrinted
    $this.Timestamp = $Timestamp
    $this.ErrorMessage = $ErrorMessage
  }
}

class ExceptionType {
  [string]$Name
  [string]$BaseType
  [string]$TypeName
  [string]$Description
  [string]$Assembly
  [bool]$IsLoaded
  [bool]$IsPublic
  ExceptionType() {}
  ExceptionType([hashtable]$obj) {
    $obj.Keys.ForEach({
        if ($null -ne $obj.$_) {
          $this.$_ = $obj.$_
        }
      }
    )
  }
}

class ErrorManager {
  # A Hashstable of common used exceptions and their descriptions:
  static [hashtable] $CommonExceptions = [Hashtable]@{
    'System.ArgumentOutOfRangeException'                                              = 'The Value Of An Argument Is Outside The Allowable Range Of Values As Defined By The Invoked Method.'
    'System.Diagnostics.Tracing.EventSourceException'                                 = 'The Error Occurs During Event Tracing For Windows (ETW).'
    'System.ServiceModel.MsmqException'                                               = 'Encapsulates Errors Returned By Message Queuing (MSMQ). This Exception Is Thrown By The Message Queuing Transport And The Message Queuing Integration Channel.'
    'System.Transactions.TransactionException'                                        = 'You Attempt To Do Work On A Transaction That Cannot Accept New Work.'
    'System.Data.Common.DbException'                                                  = 'The Base Class For All Exceptions Thrown On Behalf Of The Data Source.'
    'System.Data.EvaluateException'                                                   = 'The System.Data.Datacolumn.Expression Property Of A System.Data.Datacolumn Cannot Be Evaluated.'
    'System.Security.XmlSyntaxException'                                              = 'There Is A Syntax Error In XML Parsing.'
    'System.NotImplementedException'                                                  = 'A Requested Method Or Operation Is Not Implemented.'
    'System.Net.NetworkInformation.PingException'                                     = 'A System.Net.Networkinformation.Ping.Send Or System.Net.Networkinformation.Ping.Sendasync Method Calls A Method That Throws An Exception.'
    'System.DirectoryServices.ActiveDirectory.ActiveDirectoryServerDownException'     = 'The System.Directoryservices.Activedirectory.Activedirectoryserverdownexception Class Exception Is Thrown When A Server Is Unavailable To Respond To A Service Request.'
    'Microsoft.CSharp.RuntimeBinder.RuntimeBinderInternalCompilerException'           = 'Represents An Error That A Dynamic Bind In The C# Runtime Binder Is Processed.'
    'System.Web.HttpRequestValidationException'                                       = 'A Potentially Malicious Input String Is Received From The Client As Part Of The Request Data.'
    'System.Data.InvalidConstraintException'                                          = 'Incorrectly Trying To Create Or Access A Relation.'
    'System.ServiceModel.EndpointNotFoundException'                                   = 'A Remote Endpoint Could Not Be Found Or Reached.'
    'System.Data.Odbc.OdbcException'                                                  = 'The Exception That Is Generated When A Warning Or Error Is Returned By An ODBC Data Source.'
    'System.Data.DuplicateNameException'                                              = 'A Duplicate Database Object Name Is Encountered During An Add Operation In A System.Data.Dataset -Related Object.'
    'System.Transactions.TransactionAbortedException'                                 = 'An Operation Is Attempted On A Transaction That Has Already Been Rolled Back, Or An Attempt Is Made To Commit The Transaction And The Transaction Aborts.'
    'System.Web.Management.SqlExecutionException'                                     = 'Defines A Class For SQL Execution Exceptions In The System.Web.Management Namespace.'
    'System.Data.SqlTypes.SqlTruncateException'                                       = 'You Set A Value Into A System.Data.Sqltypes Structure Would Truncate That Value.'
    'System.Management.Instrumentation.InstrumentationBaseException'                  = 'Represents The Base Provider-Related Exception.'
    'System.Management.Instrumentation.InstanceNotFoundException'                     = 'The Exception Thrown To Indicate That No Instances Are Returned By A Provider.'
    'System.ObjectDisposedException'                                                  = 'An Operation Is Performed On A Disposed Object.'
    'System.EntryPointNotFoundException'                                              = 'An Attempt To Load A Class Failed Due To The Absence Of An Entry Method.'
    'System.Security.VerificationException'                                           = 'The Security Policy Requires Code To Be Type Safe And The Verification Process Is Unable To Verify That The Code Is Type Safe.'
    'System.ServiceModel.ActionNotSupportedException'                                 = 'This Exception Is Typically Thrown On The Client When The Action Related To The Operation Invoked Does Not Match Any Action Of Operations In The Server.'
    'System.UriTemplateMatchException'                                                = 'Represents An Error When Matching A System.Uri To A System.Uritemplatetable.'
    'System.Threading.ThreadStartException'                                           = 'A Failure Occurs In A Managed Thread After The Underlying Operating System Thread Has Been Started, But Before The Thread Is Ready To Execute User Code.'
    'System.Runtime.InteropServices.InvalidOleVariantTypeException'                   = 'The Marshaler When It Encounters An Argument Of A Variant Type That Can Not Be Marshaled To Managed Code.'
    'System.Data.TypedDataSetGeneratorException'                                      = 'A Name Conflict Occurs While Generating A Strongly Typed System.Data.Dataset.'
    'System.DivideByZeroException'                                                    = 'There Is An Attempt To Divide An Integral Or Decimal Value By Zero.'
    'System.Resources.MissingManifestResourceException'                               = 'The Main Assembly Does Not Contain The Resources For The Neutral Culture, And An Appropriate Satellite Assembly Is Missing.'
    'System.ServiceModel.Dispatcher.NavigatorInvalidBodyAccessException'              = 'An System.Xml.Xpath.Xpathnavigator Is Directed To Examine The Body Of An Unbuffered Message.'
    'System.Data.DeletedRowInaccessibleException'                                     = 'An Action Is Tried On A System.Data.Datarow That Has Been Deleted.'
    'System.Data.DataException'                                                       = 'Errors Are Generated Using ADO.NET Components.'
    'System.Data.NoNullAllowedException'                                              = 'You Try To Insert A Null Value Into A Column Where System.Data.Datacolumn.Allowdbnull Is Set To False.'
    'System.IO.InternalBufferOverflowException'                                       = 'The Internal Buffer Overflows.'
    'System.DirectoryServices.ActiveDirectory.ForestTrustCollisionException'          = 'This Exception Is Thrown When A Trust Collision Occurs During A Trust Relationship Management Request.'
    'System.Threading.ThreadAbortException'                                           = 'A Call Is Made To The System.Threading.Thread.Abort(System.Object) Method.'
    'System.Runtime.Serialization.SerializationException'                             = 'The Error Occurs During Serialization Or Deserialization.'
    'System.Data.OleDb.OleDbException'                                                = 'The Underlying Provider Returns A Warning Or Error For An OLE DB Data Source.'
    'System.DuplicateWaitObjectException'                                             = 'An Object Appears More Than Once In An Array Of Synchronization Objects.'
    'System.Data.DBConcurrencyException'                                              = 'The System.Data.Common.Dataadapter During An Insert, Update, Or Delete Operation If The Number Of Rows Affected Equals Zero.'
    'System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException' = 'This Exception Is Thrown When A Requested Object Is Not Found In The Underlying Directory Store.'
    'System.Data.Linq.ForeignKeyReferenceAlreadyHasValueException'                    = 'Represents Errors That Occur When An Attempt Is Made To Change A Foreign Key When The Entity Is Already Loaded.'
    'System.Net.ProtocolViolationException'                                           = 'An Error Is Made While Using A Network Protocol.'
    'System.ServiceModel.ServerTooBusyException'                                      = 'A Server Is Too Busy To Accept A Message.'
    'System.ServiceModel.Security.ExpiredSecurityTokenException'                      = 'Exception Thrown When A Cardspace Security Token Expires.'
    'System.Runtime.InteropServices.SafeArrayTypeMismatchException'                   = 'The Type Of The Incoming SAFEARRAY Does Not Match The Type Specified In The Managed Signature.'
    'System.StackOverflowException'                                                   = 'The Execution Stack Overflows Because It Contains Too Many Nested Method Calls.'
    'System.Management.Instrumentation.InstrumentationException'                      = 'Represents A Provider-Related Exception.'
    'System.Threading.WaitHandleCannotBeOpenedException'                              = 'An Attempt Is Made To Open A System Mutex Or Semaphore That Does Not Exist.'
    'System.MissingMemberException'                                                   = 'There Is An Attempt To Dynamically Access A Class Member That Does Not Exist.'
    'System.AggregateException'                                                       = 'Represents One Or More Errors That Occur During Application Execution.'
    'System.IO.FileLoadException'                                                     = 'A Managed Assembly Is Found But Cannot Be Loaded.'
    'System.InvalidTimeZoneException'                                                 = 'Time Zone Information Is Invalid.'
    'System.Runtime.InteropServices.SEHException'                                     = 'Represents Structured Exception Handling (SEH) Errors.'
    'System.Diagnostics.Eventing.Reader.EventLogReadingException'                     = 'Represents An Exception Is Thrown When An Error Occurred While Reading, Querying, Or Subscribing To The Events In An Event Log.'
    'System.Data.RowNotInTableException'                                              = 'You Try To Perform An Operation On A System.Data.Datarow That Is Not In A System.Data.Datatable.'
    'System.InsufficientExecutionStackException'                                      = 'There Is Insufficient Execution Stack Available To Allow Most Methods To Execute.'
    'System.IO.InvalidDataException'                                                  = 'A Data Stream Is In An Invalid Format.'
    'System.Reflection.ReflectionTypeLoadException'                                   = 'The System.Reflection.Module.Gettypes Method If Any Of The Classes In A Module Cannot Be Loaded.'
    'Microsoft.SqlServer.Server.InvalidUdtException'                                  = 'This Exception Is Thrown When SQL Server Or The ADO.NET System.Data.Sqlclient Provider Detects An Invalid User-Defined Type (UDT).'
    'System.Data.InRowChangingEventException'                                         = 'You Call The System.Data.Datarow.Endedit Method Within The System.Data.Datatable.Rowchanging Event.'
    'System.ServiceModel.Dispatcher.MessageFilterException'                           = 'The Base Class For The Exceptions That Are Thrown When The Quota Of Nodes Inspected By A Filter Is Exceeded.'
    'System.ServiceModel.CommunicationObjectAbortedException'                         = 'The Call Is To An System.Servicemodel.Icommunicationobject Object That Has Aborted.'
    'System.Reflection.TargetException'                                               = 'An Attempt Is Made To Invoke An Invalid Target.'
    'System.DirectoryServices.ActiveDirectory.ActiveDirectoryOperationException'      = 'The System.Directoryservices.Activedirectory.Activedirectoryoperationexception Class Exception Is Thrown When An Underlying Directory Operation Failed.'
    'System.Diagnostics.Eventing.Reader.EventLogException'                            = 'Represents The Base Class For All The Exceptions That Are Thrown When An Error Occurs While Reading Event Log Related Information.'
    'System.ArrayTypeMismatchException'                                               = 'An Attempt Is Made To Store An Element Of The Wrong Type Within An Array.'
    'System.MethodAccessException'                                                    = 'There Is An Invalid Attempt To Access A Method, Such As Accessing A Private Method From Partially Trusted Code.'
    'System.ArgumentException'                                                        = 'One Of The Arguments Provided To A Method Is Not Valid.'
    'System.DataMisalignedException'                                                  = 'A Unit Of Data Is Read From Or Written To An Address That Is Not A Multiple Of The Data Size.'
    'System.Threading.LockRecursionException'                                         = 'Recursive Entry Into A Lock Is Not Compatible With The Recursion Policy For The Lock.'
    'System.Security.Cryptography.CryptographicException'                             = 'The Error Occurs During A Cryptographic Operation.'
    'System.TypeAccessException'                                                      = 'A Method Attempts To Use A Type That It Does Not Have Access To.'
    'System.Data.SqlTypes.SqlAlreadyFilledException'                                  = 'The System.Data.Sqltypes.Sqlalreadyfilledexception Class Is Not Intended For Use As A Stand-Alone Component, But As A Class From Which Other Classes Derive Standard Functionality.'
    'System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException'   = 'This Exception Is Thrown When An Active Directory Domain Services Object Is Created And That Object Already Exists In The Underlying Directory Store.'
    'System.CannotUnloadAppDomainException'                                           = 'An Attempt To Unload An Application Domain Failed.'
    'System.UnauthorizedAccessException'                                              = 'The Operating System Denies Access Because Of An I/O Error Or A Specific Type Of Security Error.'
    'System.ServiceModel.Dispatcher.InvalidBodyAccessException'                       = 'An Abstract Base Class For The Exceptions That Are Thrown If An Attempt Is Made To Access The Body Of A Message When It Is Not Allowed.'
    'System.IO.DriveNotFoundException'                                                = 'Trying To Access A Drive Or Share That Is Not Available.'
    'System.ServiceModel.Dispatcher.FilterInvalidBodyAccessException'                 = 'A Filter Or Filter Table Attempts To Access The Body Of An Unbuffered Message.'
    'System.UriFormatException'                                                       = 'An Invalid Uniform Resource Identifier (URI) Is Detected.'
    'System.ComponentModel.InvalidEnumArgumentException'                              = 'Using Invalid Arguments That Are Enumerators.'
    'System.TypeInitializationException'                                              = 'The Exception Is Thrown As A Wrapper Around The Class Initializer.'
    'System.Runtime.InteropServices.SafeArrayRankMismatchException'                   = 'The Rank Of An Incoming SAFEARRAY Does Not Match The Rank Specified In The Managed Signature.'
    'System.Security.Principal.IdentityNotMappedException'                            = 'Represents An Exception For A Principal Whose Identity Could Not Be Mapped To A Known Identity.'
    'System.TypeUnloadedException'                                                    = 'There Is An Attempt To Access An Unloaded Class.'
    'System.Configuration.SettingsPropertyNotFoundException'                          = 'Provides An Exception For System.Configuration.Settingsproperty Objects That Are Not Found.'
    'System.ServiceModel.Channels.InvalidChannelBindingException'                     = 'The Binding Specified Is Not Consistent With The Contract Requirements For The Service.'
    'System.ServiceModel.AddressAlreadyInUseException'                                = 'An Address Is Unavailable Because It Is Already In Use.'
    'System.Configuration.Install.InstallException'                                   = 'The Error Occurs During The Commit, Rollback, Or Uninstall Phase Of An Installation.'
    'System.Security.SecurityException'                                               = 'A Security Error Is Detected.'
    'System.Resources.MissingSatelliteAssemblyException'                              = 'The Satellite Assembly For The Resources Of The Default Culture Is Missing.'
    'System.Net.CookieException'                                                      = 'An Error Is Made Adding A System.Net.Cookie To A System.Net.Cookiecontainer.'
    'System.ServiceModel.ProtocolException'                                           = 'The Exception Seen On The Client Is Thrown When Communication With The Remote Party Is Impossible Due To Mismatched Data Transfer Protocols.'
    'System.ServiceModel.Security.SecurityAccessDeniedException'                      = 'Represents The Security Exception Is Thrown When A Security Authorization Request Failed.'
    'System.Data.OperationAbortedException'                                           = 'This Exception Is Thrown When An Ongoing Operation Is Aborted By The User.'
    'System.Transactions.TransactionInDoubtException'                                 = 'An Operation Is Attempted On A Transaction That Is In Doubt, Or An Attempt Is Made To Commit The Transaction And The Transaction Becomes Indoubt.'
    'System.Security.Cryptography.CryptographicUnexpectedOperationException'          = 'An Unexpected Operation Occurs During A Cryptographic Operation.'
    'System.Data.StrongTypingException'                                               = 'A Strongly Typed System.Data.Dataset When The User Accesses A Dbnull Value.'
    'System.Data.Linq.ChangeConflictException'                                        = 'This Exception Is Thrown When An Update Failed Because Database Values Have Been Updated Since The Client Last Read Them.'
    'System.SystemException'                                                          = 'Serves As The Base Class For System Exceptions Namespace.'
    'System.ServiceModel.Security.MessageSecurityException'                           = 'Represents An Exception That Occurred When There Is Something Wrong With The Security Applied On A Message.'
    'System.ComponentModel.Design.CheckoutException'                                  = 'An Attempt To Check Out A File That Is Checked Into A Source Code Management Program Is Canceled Or Failed.'
    'System.MissingFieldException'                                                    = 'There Is An Attempt To Dynamically Access A Field That Does Not Exist.'
    'System.Security.HostProtectionException'                                         = 'A Denied Host Resource Is Detected.'
    'System.Threading.SemaphoreFullException'                                         = 'The System.Threading.Semaphore.Release Method Is Called On A Semaphore Whose Count Is Already At The Maximum.'
    'System.Web.HttpUnhandledException'                                               = 'A Generic Exception Occurs.'
    'System.Configuration.SettingsPropertyIsReadOnlyException'                        = 'Provides An Exception For Read-Only System.Configuration.Settingsproperty Objects.'
    'System.Data.InvalidExpressionException'                                          = 'You Try To Add A System.Data.Datacolumn That Contains An Invalid System.Data.Datacolumn.Expression To A System.Data.Datacolumncollection.'
    'System.IO.EndOfStreamException'                                                  = 'Reading Is Attempted Past The End Of A Stream.'
    'System.ApplicationException'                                                     = 'Serves As The Base Class For Application-Defined Exceptions.'
    'System.ServiceModel.MsmqPoisonMessageException'                                  = 'Encapsulates The Channel Detects That The Message Is A Poison Message.'
    'System.Web.UI.WebControls.LinqDataSourceValidationException'                     = 'Describes An Exception That Occurred During Validation Of New Or Modified Values Before Values Are Inserted, Updated, Or Deleted By A System.Web.UI.Webcontrols.Linqdatasource Control.'
    'System.TimeZoneNotFoundException'                                                = 'A Time Zone Cannot Be Found.'
    'System.ComponentModel.InvalidAsynchronousStateException'                         = 'This Exception Is Thrown When A Thread On Which An Operation Should Execute No Longer Exists Or Has No Message Loop.'
    'System.IO.IsolatedStorage.IsolatedStorageException'                              = 'An Operation In Isolated Storage Failed.'
    'System.ExecutionEngineException'                                                 = 'There Is An Internal Error In The Execution Engine Of The Common Language Runtime.'
    'System.Runtime.Remoting.RemotingTimeoutException'                                = 'The Server Or The Client Cannot Be Reached For A Previously Specified Period Of Time.'
    'System.DllNotFoundException'                                                     = 'A DLL Specified In A DLL Import Cannot Be Found.'
    'System.Data.ConstraintException'                                                 = 'Attempting An Action That Violates A Constraint.'
    'System.Diagnostics.Eventing.Reader.EventLogProviderDisabledException'            = 'A Specified Event Provider Name References A Disabled Event Provider. A Disabled Event Provider Cannot Publish Events.'
    'System.ArgumentNullException'                                                    = 'A Null Reference (Nothing In Visual Basic) Is Passed To A Method That Does Not Accept It As A Valid Argument.'
    'System.Data.ReadOnlyException'                                                   = 'You Try To Change The Value Of A Read-Only Column.'
    'System.ComponentModel.WarningException'                                          = 'Specifies An Exception That Is Handled As A Warning Instead Of An Error.'
    'System.ServiceModel.Channels.RetryException'                                     = 'Represents A Retry Exception That Can Be Used By A Messaging Host Such As System.Servicemodel.Activities,Workflowservicehost To Communicate Any Cancellation Of An Attempted Operation To The Client.'
    'System.Threading.SynchronizationLockException'                                   = 'A Method Requires The Caller To Own The Lock On A Given Monitor, And The Method Is Invoked By A Caller That Does Not Own That Lock.'
    'System.Net.WebException'                                                         = 'The Error Occurs While Accessing The Network Through A Pluggable Protocol.'
    'System.Web.Security.MembershipCreateUserException'                               = 'A User Is Not Successfully Created By A Membership Provider.'
    'System.Runtime.InteropServices.COMException'                                     = 'An Unrecognized HRESULT Is Returned From A COM Method Call.'
    'System.IO.PathTooLongException'                                                  = 'A Path Or File Name Is Longer Than The System-Defined Maximum Length.'
    'System.Collections.Generic.KeyNotFoundException'                                 = 'The Key Specified For Accessing An Element In A Collection Does Not Match Any Key In The Collection.'
    'System.MemberAccessException'                                                    = 'An Attempt To Access A Class Member Failed.'
    'System.OverflowException'                                                        = 'An Arithmetic, Casting, Or Conversion Operation In A Checked Context Results In An Overflow.'
    'System.IO.DirectoryNotFoundException'                                            = 'Part Of A File Or Directory Cannot Be Found.'
    'System.ServiceModel.PoisonMessageException'                                      = 'An Exception Is Thrown When The Message Is Deemed Poison. A Message Is Poisoned If It Failed Repeated Attempts To Deliver The Message.'
    'System.Web.Query.Dynamic.ParseException'                                         = 'Represents Errors That Occur When A System.Web.UI.Webcontrols.Linqdatasource Control Parses Values To Create A Query.'
    'System.ServiceModel.AddressAccessDeniedException'                                = 'Access To The Address Is Denied.'
    'System.Threading.Tasks.TaskSchedulerException'                                   = 'Represents An Exception Used To Communicate An Invalid Operation By A System.Threading.Tasks.Taskscheduler.'
    'System.AppDomainUnloadedException'                                               = 'An Attempt Is Made To Access An Unloaded Application Domain.'
    'System.Web.HttpException'                                                        = 'Describes An Exception That Occurred During The Processing Of HTTP Requests.'
    'System.Threading.ThreadInterruptedException'                                     = 'A System.Threading.Thread Is Interrupted While It Is In A Waiting State.'
    'System.Net.HttpListenerException'                                                = 'The Error Occurs Processing An HTTP Request.'
    'System.Security.Authentication.InvalidCredentialException'                       = 'Authentication Failed when An Authentication Stream And Cannot Be Retried.'
    'System.Xml.Schema.XmlSchemaValidationException'                                  = 'XML Schema Definition Language (XSD) Schema Validation Errors And Warnings Are Encountered In An XML Document Being Validated.'
    'System.PlatformNotSupportedException'                                            = 'A Feature Does Not Run On A Particular Platform.'
    'System.Net.Mail.SmtpFailedRecipientsException'                                   = 'E-Mail Is Sent Using An System.Net.Mail.Smtpclient And Cannot Be Delivered To All Recipients.'
    'System.Web.Caching.TableNotEnabledForNotificationException'                      = 'A System.Web.Caching.Sqlcachedependency Class Is Used Against A Database Table That Is Not Enabled For Change Notifications.'
    'System.ComponentModel.LicenseException'                                          = 'A Component Cannot Be Granted A License.'
    'System.OutOfMemoryException'                                                     = 'There Is Not Enough Memory To Continue The Execution Of A Program.'
    'System.Web.Services.Protocols.SoapHeaderException'                               = 'The SOAP Representation Of A Server Error.'
    'System.DirectoryServices.DirectoryServicesCOMException'                          = 'Contains Extended Error Information About An Error That Occurred When The System.Directoryservices.Directoryentry.Invoke(System.String,System.Object[]) Method Is Called.'
    'System.Globalization.CultureNotFoundException'                                   = 'A Method Is Invoked Which Attempts To Construct A Culture That Is Not Available On The Machine.'
    'System.Reflection.AmbiguousMatchException'                                       = 'Binding To A Member Results In More Than One Member Matching The Binding Criteria.'
    'System.InvalidOperationException'                                                = 'A Method Call Is Invalid For The Object S Current State.'
    'System.Reflection.TargetParameterCountException'                                 = 'The Number Of Parameters For An Invocation Does Not Match The Number Expected.'
    'System.OperationCanceledException'                                               = 'The Exception Is Thrown In A Thread Upon Cancellation Of An Operation That The Thread Was Executing.'
    'System.FormatException'                                                          = 'The Format Of An Argument Is Invalid, Or When A Composite Format String Is Not Well Formed.'
    'System.Configuration.SettingsPropertyWrongTypeException'                         = 'Provides An Exception Is Thrown When An Invalid Type Is Used With A System.Configuration.Settingsproperty Object.'
    'System.NullReferenceException'                                                   = 'There Is An Attempt To Dereference A Null Object Reference.'
    'System.Configuration.Provider.ProviderException'                                 = 'A Configuration Provider Error Has Occurred. This Exception Class Is Also Used By Providers To Throw Exceptions When Internal Errors Occur Within The Provider That Do Not Map To Other Pre-Existing Exception Classes.'
    'System.Security.AccessControl.PrivilegeNotHeldException'                         = 'A Method In The System.Security.Accesscontrol Namespace Attempts To Enable A Privilege That It Does Not Have.'
    'System.BadImageFormatException'                                                  = 'The File Image Of A Dynamic Link Library (DLL) Or An Executable Program Is Invalid.'
    'System.InvalidProgramException'                                                  = 'A Program Contains Invalid Microsoft Intermediate Language (MSIL) Or Metadata. Generally This Indicates A Bug In The Compiler That Generated The Program.'
    'System.Data.Linq.DuplicateKeyException'                                          = 'This Exception Is Thrown When An Attempt Is Made To Add An Object To The Identity Cache By Using A Key That Is Already Being Used.'
    'System.ServiceModel.MessageHeaderException'                                      = 'The Expectations Regarding Headers Of A SOAP Message Are Not Satisfied When The Message Is Processed.'
    'System.Web.UI.ViewStateException'                                                = 'The View State Cannot Be Loaded Or Validated.'
    'System.ComponentModel.Win32Exception'                                            = 'Throws An Exception For A Win32 Error Code.'
    'System.IO.PipeException'                                                         = 'This Exception Is Thrown When An Error Occurs Within A Named Pipe.'
    'System.Xml.XmlException'                                                         = 'Returns Detailed Information About The Last Exception.'
    'System.Runtime.CompilerServices.RuntimeWrappedException'                         = 'Wraps An Exception That Does Not Derive From The System.Exception Class.'
    'System.Reflection.InvalidFilterCriteriaException'                                = 'The Exception Is Thrown In System.Type.Findmembers(System.Reflection.Membertypes,System.Reflection.Bindingflags,System.Reflection.Memberfilter,System.Object) When The Filter Criteria Is Not Valid For The Type Of Filter You Are Using.'
    'System.ServiceModel.InvalidMessageContractException'                             = 'Represents A Message Contract That Is Not Valid.'
    'System.ServiceModel.Dispatcher.MultipleFilterMatchesException'                   = 'Multiple Filters Match, But Only One Was Expected.'
    'System.IO.FileNotFoundException'                                                 = 'An Attempt To Access A File That Does Not Exist On Disk Failed.'
    'System.InsufficientMemoryException'                                              = 'A Check For Sufficient Available Memory Failed.'
    'Microsoft.CSharp.RuntimeBinder.RuntimeBinderException'                           = 'Represents An Error That A Dynamic Bind In The C# Runtime Binder Is Processed.'
    'System.Runtime.Serialization.InvalidDataContractException'                       = 'The System.Runtime.Serialization.Datacontractserializer Or System.Runtime.Serialization.Netdatacontractserializer Encounters An Invalid Data Contract During Serialization And Deserialization.'
    'System.Runtime.InteropServices.InvalidComObjectException'                        = 'An Invalid COM Object Is Used.'
    'System.Web.HttpCompileException'                                                 = 'A Compiler Error Occurs.'
    'System.Exception'                                                                = 'Represents Errors That Occur During Application Execution.To Browse The .NET Framework Source Code For This Type, See The Reference Source.'
    'System.Net.Mail.SmtpException'                                                   = 'The System.Net.Mail.Smtpclient Is Not Able To Complete A System.Net.Mail.Smtpclient.Send Or System.Net.Mail.Smtpclient.Sendasync Operation.'
    'System.DirectoryServices.ActiveDirectory.SyncFromAllServersOperationException'   = 'This Exception Is Thrown When The Request To Synchronize From All Servers Failed.'
    'System.MissingMethodException'                                                   = 'There Is An Attempt To Dynamically Access A Method That Does Not Exist.'
    'System.Net.Mail.SmtpFailedRecipientException'                                    = 'The System.Net.Mail.Smtpclient Is Not Able To Complete A System.Net.Mail.Smtpclient.Send Or System.Net.Mail.Smtpclient.Sendasync Operation To A Particular Recipient.'
    'System.IO.IOException'                                                           = 'An I/O Error Occurs.'
    'System.Net.WebSockets.WebSocketException'                                        = 'Represents An Exception That Occurred When Performing An Operation On A Websocket Connection.'
    'System.Diagnostics.Eventing.Reader.EventLogNotFoundException'                    = 'A Requested Event Log (Usually Specified By The Name Of The Event Log Or The Path To The Event Log File) Does Not Exist.'
    'System.FieldAccessException'                                                     = 'There Is An Invalid Attempt To Access A Private Or Protected Field Inside A Class.'
    'System.Data.VersionNotFoundException'                                            = 'You Try To Return A Version Of A System.Data.Datarow That Has Been Deleted.'
    'System.ContextMarshalException'                                                  = 'An Attempt To Marshal An Object Across A Context Boundary Failed.'
    'System.TypeLoadException'                                                        = 'Type-Loading Failures Occur.'
    'System.Data.SqlTypes.SqlNotFilledException'                                      = 'The System.Data.Sqltypes.Sqlnotfilledexception Class Is Not Intended For Use As A Stand-Alone Component, But As A Class From Which Other Classes Derive Standard Functionality.'
    'System.Web.Caching.DatabaseNotEnabledForNotificationException'                   = 'A SQL Server Database Is Not Enabled To Support Dependencies Associated With The System.Web.Caching.Sqlcachedependency Class.'
    'System.TimeoutException'                                                         = 'The Time Allotted For A Process Or Operation Has Expired.'
    'System.IndexOutOfRangeException'                                                 = 'An Attempt Is Made To Access An Element Of An Array Or Collection With An Index That Is Outside Its Bounds.'
    'System.Xml.XPath.XPathException'                                                 = 'Provides An Error Occurs While Processing An Xpath Expression.'
    'System.AccessViolationException'                                                 = 'There Is An Attempt To Read Or Write Protected Memory.'
    'System.ServiceModel.ChannelTerminatedException'                                  = 'This Exception Is Typically Thrown On The Client When A Channel Is Terminated Due To Server Closing The Associated Connection.'
    'System.Threading.BarrierPostPhaseException'                                      = 'The Post-Phase Action Of A System.Threading.Barrier Failed'
    'System.Web.HttpParseException'                                                   = 'A Parse Error Occurs.'
    'System.Xml.Schema.XmlSchemaInferenceException'                                   = 'Returns Information About Errors Encountered By The System.Xml.Schema.Xmlschemainference Class While Inferring A Schema From An XML Document.'
    'System.Security.Authentication.AuthenticationException'                          = 'Authentication Failed when An Authentication Stream.'
    'System.Threading.AbandonedMutexException'                                        = 'One Thread Acquires A System.Threading.Mutex Object That Another Thread Has Abandoned By Exiting Without Releasing It.'
    'System.ServiceModel.ServiceActivationException'                                  = 'A Service Failed To Activate.'
    'System.ServiceModel.CommunicationException'                                      = 'Represents A Communication Error In Either The Service Or Client Application.'
    'System.Security.Policy.PolicyException'                                          = 'Policy Forbids Code To Run.'
    'System.NotSupportedException'                                                    = 'An Invoked Method Is Not Supported, Or When There Is An Attempt To Read, Seek, Or Write To A Stream That Does Not Support The Invoked Functionality.'
    'System.ServiceModel.Dispatcher.XPathNavigatorException'                          = 'The Quota Of Nodes Allowed To Be Inspected By An Xpathnavigator Is Exceeded.'
    'System.Web.Services.Protocols.SoapException'                                     = 'An XML Web Service Method Is Called Over SOAP And An Exception Occurs.'
    'System.Runtime.Remoting.RemotingException'                                       = 'Something Has Gone Wrong During Remoting.'
    'System.InvalidCastException'                                                     = 'The Exception Is Thrown For Invalid Casting Or Explicit Conversion.'
    'System.ServiceModel.CommunicationObjectFaultedException'                         = 'A Call Is Made To A Communication Object That Has Faulted.'
    'System.Runtime.InteropServices.MarshalDirectiveException'                        = 'The Marshaler When It Encounters A System.Runtime.Interopservices.Marshalasattribute It Does Not Support.'
    'System.Xml.Xsl.XsltCompileException'                                             = 'The Load Method When An Error Is Found In The XSLT Style Sheet.'
    'System.Threading.ThreadStateException'                                           = 'A System.Threading.Thread Is In An Invalid System.Threading.Thread.Threadstate For The Method Call.'
    'System.Threading.Tasks.TaskCanceledException'                                    = 'Represents An Exception Used To Communicate Task Cancellation.'
    'System.Data.SyntaxErrorException'                                                = 'The System.Data.Datacolumn.Expression Property Of A System.Data.Datacolumn Contains A Syntax Error.'
    'System.Runtime.InteropServices.ExternalException'                                = 'The Base Exception Type For All COM Interop Exceptions And Structured Exception Handling (SEH) Exceptions.'
    'System.Web.Security.MembershipPasswordException'                                 = 'A Password Cannot Be Retrieved From The Password Store.'
    'System.Data.MissingPrimaryKeyException'                                          = 'You Try To Access A Row In A Table That Has No Primary Key.'
    'System.ServiceModel.FaultException'                                              = 'Represents A SOAP Fault.'
    'System.Net.Sockets.SocketException'                                              = 'A Socket Error Occurs.'
    'System.Configuration.ConfigurationErrorsException'                               = 'The Current Value Is Not One Of The System.Web.Configuration.Pagessection.Enablesessionstate Values.'
    'System.Configuration.ConfigurationException'                                     = 'A Configuration System Error Has Occurred.'
    'System.Xml.Xsl.XsltException'                                                    = 'The Error Occurs While Processing An XSLT Transformation.'
    'System.Reflection.CustomAttributeFormatException'                                = 'The Binary Format Of A Custom Attribute Is Invalid.'
    'System.RankException'                                                            = 'An Array With The Wrong Number Of Dimensions Is Passed To A Method.'
    'System.Reflection.TargetInvocationException'                                     = 'Methods Invoked Through Reflection.'
    'System.Data.SqlTypes.SqlNullValueException'                                      = 'The Value Property Of A System.Data.Sqltypes Structure Is Set To Null.'
    'System.ServiceModel.Security.SecurityNegotiationException'                       = 'Indicates That An Error Occurred While Negotiating The Security Context For A Message.'
    'System.Runtime.Remoting.ServerException'                                         = 'The Exception Is Thrown To Communicate Errors To The Client When The Client Connects To Non-.NET Framework Applications That Cannot Throw Exceptions.'
    'System.NotFiniteNumberException'                                                 = 'A Floating-Point Value Is Positive Infinity, Negative Infinity, Or Not-A-Number (Nan).'
    'System.ServiceModel.Channels.RedirectionException'                               = 'Represents An Error That Occurs In Redirection Processing.'
    'System.Net.NetworkInformation.NetworkInformationException'                       = 'The Error Occurs While Retrieving Network Information.'
    'System.Transactions.TransactionPromotionException'                               = 'A Promotion Failed.'
    'System.Text.RegularExpressions.RegexMatchTimeoutException'                       = 'The Execution Time Of A Regular Expression Pattern-Matching Method Exceeds Its Time-Out Interval.'
    'System.Diagnostics.Eventing.Reader.EventLogInvalidDataException'                 = 'An Event Provider Publishes Invalid Data In An Event.'
    'System.MulticastNotSupportedException'                                           = 'There Is An Attempt To Combine Two Delegates Based On The System.Delegate Type Instead Of The System.Multicastdelegate Type.'
    'System.Management.ManagementException'                                           = 'Represents Management Exceptions.'
    'System.ArithmeticException'                                                      = 'The Exception Is Thrown For Errors In An Arithmetic, Casting, Or Conversion Operation.'
    'System.Xml.Schema.XmlSchemaException'                                            = 'Returns Detailed Information About The Schema Exception.'
    'System.Transactions.TransactionManagerCommunicationException'                    = 'A Resource Manager Cannot Communicate With The Transaction Manager.'
    'System.Data.SqlClient.SqlException'                                              = 'SQL Server Returns A Warning Or Error.'
    'System.Data.SqlTypes.SqlTypeException'                                           = 'The Base Exception Class For The System.Data.Sqltypes.'
    'System.Text.DecoderFallbackException'                                            = 'A Decoder Fallback Operation Failed.'
    'System.Text.EncoderFallbackException'                                            = 'An Encoder Fallback Operation Failed.'
    'System.Drawing.Printing.InvalidPrinterException'                                 = 'You Try To Access A Printer Using Printer Settings That Are Not Valid.'
    'System.ServiceModel.QuotaExceededException'                                      = 'A Message Quota Has Been Exceeded.'
  }
  ErrorManager() {}
  static [ExceptionType[]] Get_ExceptionTypes() {
    $all = @()
    [appdomain]::currentdomain.GetAssemblies().GetTypes().Where({ $_.Name -like "*Exception" -and $null -ne $_.BaseType }).ForEach({
        [string]$FullName = $_.FullName
        $RuntimeType = $($FullName -as [type])
        $all += [ExceptionType][hashtable]@{
          Name        = $_.Name
          BaseType    = $_.BaseType
          TypeName    = $FullName
          Description = [ErrorManager]::CommonExceptions["$FullName"]
          Assembly    = $_.Assembly
          IsLoaded    = [bool]$RuntimeType
          IsPublic    = $RuntimeType.IsPublic
        }
      }
    )
    return $all.Where({ $null -ne $_.IsPublic -and !$_.TypeName.Contains('<') -and !$_.TypeName.Contains('+') -and !$_.TypeName.Contains('>') })
  }
}
#endregion Classes

# Types that will be available to users when they import the module.
$typestoExport = @(
  [ErrorMetadata], [ExceptionType], [ErrorManager]
)
$TypeAcceleratorsClass = [PsObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
foreach ($Type in $typestoExport) {
  if ($Type.FullName -in $TypeAcceleratorsClass::Get.Keys) {
    $Message = @(
      "Unable to register type accelerator '$($Type.FullName)'"
      'Accelerator already exists.'
    ) -join ' - '

    [System.Management.Automation.ErrorRecord]::new(
      [System.InvalidOperationException]::new($Message),
      'TypeAcceleratorAlreadyExists',
      [System.Management.Automation.ErrorCategory]::InvalidOperation,
      $Type.FullName
    ) | Write-Warning
  }
}
# Add type accelerators for every exportable type.
foreach ($Type in $typestoExport) {
  $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  foreach ($Type in $typestoExport) {
    $TypeAcceleratorsClass::Remove($Type.FullName)
  }
}.GetNewClosure();

$scripts = @();
$Public = Get-ChildItem "$PSScriptRoot/Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += Get-ChildItem "$PSScriptRoot/Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += $Public

foreach ($file in $scripts) {
  Try {
    if ([string]::IsNullOrWhiteSpace($file.fullname)) { continue }
    . "$($file.fullname)"
  } Catch {
    Write-Warning "Failed to import function $($file.BaseName): $_"
    $host.UI.WriteErrorLine($_)
  }
}

$Param = @{
  Function = $Public.BaseName
  Cmdlet   = '*'
  Alias    = '*'
  Verbose  = $false
}
Export-ModuleMember @Param
