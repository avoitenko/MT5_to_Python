//+------------------------------------------------------------------+
//|                                                        redis.mqh |
//|                                                        avoitenko |
//|                        https://login.mql5.com/ru/users/avoitenko |
//+------------------------------------------------------------------+
#property copyright "avoitenko"
#property link      "https://login.mql5.com/ru/users/avoitenko"

#ifndef POINTER
#define POINTER long
#endif

#define REDIS_ERR             -1
#define REDIS_OK              0

#define REDIS_REPLY_STRING    1
#define REDIS_REPLY_ARRAY     2
#define REDIS_REPLY_INTEGER   3
#define REDIS_REPLY_NIL       4
#define REDIS_REPLY_STATUS    5
#define REDIS_REPLY_ERROR     6
//+------------------------------------------------------------------+
struct timeval
  {
   int               tv_sec;
   int               tv_usec;
  };
//+------------------------------------------------------------------+
struct redisContext
  {
   int               err;        // Error flags, 0 when there is no error
   uchar             errstr[128];// String representation of error when applicable
   int               fd;
   int               flags;
   int               align1;
   POINTER           obuf;       // Write buffer
   POINTER           reader;     // Protocol reader
  };
//+------------------------------------------------------------------+
struct redisReply//48
  {
   int               type;    // REDIS_REPLY_*
   int               align1;
   long              integer; // REDIS_REPLY_INTEGER
   long              len;     // Length of string
   long              str;     // REDIS_REPLY_ERROR / REDIS_REPLY_STRING
   long              elements;// number of elements, for REDIS_REPLY_ARRAY
   long              element; // elements vector for REDIS_REPLY_ARRAY
  };
//+------------------------------------------------------------------+
struct TReply
  {
   int               type;
   int               integer;
   int               len;
   string            str;
  };
//+------------------------------------------------------------------+
#import "hiredis.dll"
POINTER redisConnect(uchar &ip[],int port);
POINTER redisConnectWithTimeout(uchar &ip[],int port,long tv);
POINTER redisConnectNonBlock(uchar &ip[],int port);

int redisSetTimeout(redisContext &c,long tv);

void _redisFree(redisContext &c);

POINTER redisCommand(redisContext &c,uchar &cmd[]);
POINTER redisCommand(redisContext &c,uchar &format[],uchar &param1[]);
POINTER redisCommand(redisContext &c,uchar &format[],uchar &param1[],uchar &param2[]);
POINTER redisCommand(redisContext &c,uchar &format[],uchar &param1[],uchar &param2[],uchar &param3[]);

int redisAppendCommand(redisContext &c,uchar &format[]);
int redisAppendCommand(redisContext &c,uchar &format[],uchar &param1[]);
int redisAppendCommand(redisContext &c,uchar &format[],uchar &param1[],uchar &param2[]);

void freeReplyObject(POINTER pointer);

#import "msvcrt.dll"
long memcpy(uchar &data[],long &src,long cnt);
long memcpy(uchar &data[],int &src,long cnt);
//long memcpy(long dst,long src,long cnt);

long memcpy(int &dst,int &src,int cnt);
long memcpy(POINTER &dst,POINTER &src,long cnt);

long memcpy(redisContext &dst,POINTER ptr,long cnt);
long memcpy(redisContext &dst,redisContext &src,long cnt);

long memcpy(redisReply &dst,POINTER ptr,int cnt);
long memcpy(redisReply &dst,redisReply &src,int cnt);

#ifndef MSVCRT_DLL
long strcpy(uchar &dst[],POINTER addr);
#endif

#import
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRedis
  {
private:
   redisContext      m_context;
   string            m_error_desc;
   //+------------------------------------------------------------------+
   bool SaveToFile(const string _filename,
                   uchar &data[])
     {
      int file_handle=FileOpen(_filename,FILE_WRITE|FILE_BIN);
      if(file_handle==INVALID_HANDLE)
        {
         Print("Error FileOpen");
         return(false);
        }
      FileWriteArray(file_handle,data);
      FileClose(file_handle);
      return(true);
     }
public:
                     CRedis()
     {
      ZeroMemory(m_context);
      m_error_desc=NULL;
     }
   //+------------------------------------------------------------------+                       
                    ~CRedis()
     {
      Free();
     }

   //+------------------------------------------------------------------+   
   int GetLastError(){return m_context.err;}

   //+------------------------------------------------------------------+   
   void Free()
     {
      _redisFree(m_context);
     }
/*
   //+------------------------------------------------------------------+   
   bool  Connect(const string _ip,
                 const int _port)
     {
      m_context.err=0;
      m_error_desc=NULL;

      //---
      uchar ip[];
      StringToCharArray(_ip,ip);
      POINTER ptr=redisConnect(ip,_port);

      //char data[512]={};
      //memcpy(data,ptr,512);
      //SaveToFile("my.bin",data);

      if(ptr==0)
        {
         m_context.err=1;
         m_error_desc="Can't allocate redis context.";
         return false;
        }

      //---
      //ZeroMemory(m_context);
      memcpy(m_context,ptr,sizeof(m_context));

      //---
      if(m_context.err!=0)
        {
         //uchar data2[256];
         //strcpy(data2,m_context.errstr);
         m_error_desc=CharArrayToString(m_context.errstr);

         return false;
        }

      //---
      return true;
     }
*/
   //+------------------------------------------------------------------+      
   bool ConnectWithTimeout(const string ip_address,
                           const int    port,
                           const int    timeout_msec=3000)
     {
      m_error_desc=NULL;

      timeval tv={};
      tv.tv_sec=timeout_msec/1000;
      tv.tv_usec=1000*(timeout_msec%1000);
      long ltv=((long)tv.tv_sec<<32)|tv.tv_usec;

      uchar address[];
      StringToCharArray(ip_address,address);
      POINTER ptr=redisConnectWithTimeout(address,port,ltv);
      if(ptr==0)
        {
         m_context.err=1;
         m_error_desc="Can't allocate redis context.";
         return false;
        }
/*
      char data[512]={};
      memcpy(data,ptr,512);
      SaveToFile("my.bin",data);
      */

      //---
      memcpy(m_context,ptr,sizeof(m_context));

      //---
      if(m_context.err!=0)
        {
         m_error_desc=CharArrayToString(m_context.errstr);
         return false;
        }

      //---
      return true;
     }
/*
   //+------------------------------------------------------------------+      
   bool ConnectNoBlock(const string ip_address,
                       const int    port)
     {
      m_error_desc=NULL;

      uchar address[];
      StringToCharArray(ip_address,address,0,StringLen(ip_address));
      POINTER ptr=redisConnectNonBlock(address,port);
      if(ptr==0)
        {
         m_context.err=1;
         m_error_desc="Can't allocate redis context.";
         return false;
        }

      memcpy(m_context,ptr,sizeof(m_context));

      //---
      if(m_context.err!=0)
        {
         m_error_desc=CharArrayToString(m_context.errstr);
         return false;
        }

      //---
      return true;
     }
     */
   //+------------------------------------------------------------------+   
   bool Command(const string _cmd,
                TReply &result)
     {
      ZeroMemory(result);
      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }

      //---
      uchar cmd[];
      StringToCharArray(_cmd,cmd);
      POINTER ptr=redisCommand(m_context,cmd);
      if(ptr==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }

      //---
      redisReply reply;
      memcpy(reply,ptr,sizeof(reply));

      result.type=reply.type;
      switch(reply.type)
        {
         case REDIS_REPLY_INTEGER:
            result.integer=(int)reply.integer;
            break;

         case REDIS_REPLY_STATUS:
         case REDIS_REPLY_ERROR:
         case REDIS_REPLY_STRING:
           {
            char str[];
            ArrayResize(str,(int)reply.len);
            strcpy(str,reply.str);
            result.str=CharArrayToString(str);
           }
         break;
        }
      freeReplyObject(ptr);
      return true;
     }
   //+------------------------------------------------------------------+   
   bool Command(const string _format,
                const string _param1,
                TReply &result)
     {

      ZeroMemory(result);

      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }

      //---
      uchar format[];
      StringToCharArray(_format,format);
      uchar param1[];
      StringToCharArray(_param1,param1);

      POINTER ptr=redisCommand(m_context,format,param1);
      if(ptr==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }
      //---
      redisReply reply;
      memcpy(reply,ptr,sizeof(reply));

      //---
      result.type=reply.type;
      switch(reply.type)
        {
         case REDIS_REPLY_INTEGER:
            result.integer=(int)reply.integer;
            break;

         case REDIS_REPLY_STATUS:
         case REDIS_REPLY_ERROR:
         case REDIS_REPLY_STRING:
           {
            uchar str[];
            ArrayResize(str,(int)reply.len);
            strcpy(str,reply.str);
            result.str=CharArrayToString(str);
           }
         break;
        }
      freeReplyObject(ptr);
      return true;
     }
   //+------------------------------------------------------------------+   
   bool Command(const string _format,
                const string _param1,
                const string _param2,
                TReply &result)
     {
      ZeroMemory(result);

      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }

      //---
      uchar format[];
      StringToCharArray(_format,format);
      uchar param1[];
      StringToCharArray(_param1,param1);
      uchar param2[];
      StringToCharArray(_param2,param2);

      POINTER ptr=redisCommand(m_context,format,param1,param2);
      if(ptr==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }
      //---
      redisReply reply;
      memcpy(reply,ptr,sizeof(reply));

      //---
      result.type=reply.type;
      switch(reply.type)
        {
         case REDIS_REPLY_INTEGER:
            result.integer=(int)reply.integer;
            break;

         case REDIS_REPLY_STATUS:
         case REDIS_REPLY_ERROR:
         case REDIS_REPLY_STRING:
           {
            uchar str[];
            ArrayResize(str,(int)reply.len);
            strcpy(str,reply.str);
            result.str=CharArrayToString(str);
           }
         break;
        }
      freeReplyObject(ptr);
      return true;
     }
   //+------------------------------------------------------------------+   
   bool Command(const string _format,
                const string _param1,
                const string _param2,
                const string _param3,
                TReply &result)
     {
      ZeroMemory(result);

      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }

      //---
      uchar format[];
      StringToCharArray(_format,format);
      uchar param1[];
      StringToCharArray(_param1,param1);
      uchar param2[];
      StringToCharArray(_param2,param2);
      uchar param3[];
      StringToCharArray(_param3,param3);

      POINTER ptr=redisCommand(m_context,format,param1,param2,param3);
      if(ptr==0)
        {
         result.type=REDIS_REPLY_ERROR;
         result.str="Invalid context.";
         m_context.err=1;
         return false;
        }
      //---
      redisReply reply;
      memcpy(reply,ptr,sizeof(reply));

      //---
      result.type=reply.type;
      switch(reply.type)
        {
         case REDIS_REPLY_INTEGER:
            result.integer=(int)reply.integer;
            break;

         case REDIS_REPLY_STATUS:
         case REDIS_REPLY_ERROR:
         case REDIS_REPLY_STRING:
           {
            uchar str[];
            ArrayResize(str,(int)reply.len);
            strcpy(str,reply.str);
            result.str=CharArrayToString(str);
           }
         break;
        }
      freeReplyObject(ptr);
      return true;
     }
/*
   //+------------------------------------------------------------------+   
   bool AppendCommand(const string _cmd)
     {
      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         m_error_desc="Invalid context.";
         return false;
        }

      //---
      uchar cmd[];
      StringToCharArray(_cmd,cmd);
      POINTER ptr=redisAppendCommand(m_context,cmd);
      if(ptr!=0)
        {
         m_context.err=1;
         m_error_desc="Invalid context.";
         return false;
        }
      return true;
     }
   //+------------------------------------------------------------------+   
   bool AppendCommand(const string _format,
                      const string _param1)
     {

      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         m_error_desc="Invalid context.";
         return false;
        }

      //---
      uchar format[];
      StringToCharArray(_format,format);
      uchar param1[];
      StringToCharArray(_param1,param1);

      POINTER ptr=redisAppendCommand(m_context,format,param1);
      if(ptr!=0)
        {
         m_context.err=1;
         m_error_desc="Invalid context.";
         return false;
        }
      return true;
     }
   //+------------------------------------------------------------------+   
   bool AppendCommand(const string _format,
                      const string _param1,
                      const string _param2)
     {
      //---
      if(m_context.err!=0 ||
         m_context.obuf==0 ||
         m_context.reader==0)
        {
         m_error_desc="Invalid context.";
         return false;
        }

      //---
      uchar format[];
      StringToCharArray(_format,format);
      uchar param1[];
      StringToCharArray(_param1,param1);
      uchar param2[];
      StringToCharArray(_param2,param2);

      POINTER ptr=redisAppendCommand(m_context,format,param1,param2);
      if(ptr!=0)
        {
         m_context.err=1;
         m_error_desc="Invalid context.";
         return false;
        }
      return true;
     }
     */
  };
//+------------------------------------------------------------------+
