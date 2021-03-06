if (exists (select * from sys.objects where name = 'proc_GetICBillNo'))
    drop proc proc_GetICBillNo
go
create proc proc_GetICBillNo
(
  @FBillTypeID varchar(50), --单据类型
  @FBillNo  VARCHAR (128) output
)
 
as
set nocount on
--------------开始存储过程
begin
--------------事务选项设置为出错全部回滚
set xact_abort on
--------------开启事务
begin tran
   declare @Fprefix varchar(50),--编号前缀
        @Fnumber varchar(20),--流水号
        @FLength int,        --流水号的长度
        @FDateStr varchar(20),--日期字符
        @FProjectID varchar(20),--格式标识符 
        @FClassIndex int,  --排序(用于循环找出类型)
        @FprefixAndFDateStr varchar(128),--编号前缀+流水号依据
        @Index int  --(循环标)
        set @FBillNo =''  

select @FClassIndex= COUNT(1) from t_billcoderule a
 left join t_option b on a.fprojectid=b.fprojectid and a.fformatindex=b.fid
 left join t_checkproject c on a.fbilltype = c.fbilltypeid and a.fprojectval = c.ffield
 where a.fbilltypeid = @FBillTypeID
 set @Index=1
 while(@Index<=@FClassIndex)
 begin
 select @FProjectID= a.FProjectID from t_billcoderule a
 left join t_option b on a.fprojectid=b.fprojectid and a.fformatindex=b.fid
 left join t_checkproject c on a.fbilltype = c.fbilltypeid and a.fprojectval = c.ffield
 where a.fbilltypeid = @FBillTypeID and a.FClassIndex=@Index
 if(@FProjectID='1')
 begin
 --编号前缀    
select @Fprefix=a.FProjectVal from t_billcoderule a
 left join t_option e on a.fprojectid=e.fprojectid and a.fformatindex=e.fid
 Left OUter join t_checkproject b on a.fbilltype=b.fbilltypeid and a.fprojectval=b.ffield
 where a.fbilltypeid = @FBillTypeID and  a.FProjectID=1 and a.FClassIndex=@Index order by a.FClassIndex
  set @FBillNo=isnull(@FBillNo,'')+isnull(@Fprefix,'')
  set @FprefixAndFDateStr=isnull(@FprefixAndFDateStr,'')+isnull(@Fprefix,'')
 end
 if(@FProjectID='2')
 begin
  --日期字符
 select @FDateStr=a.FProjectVal from t_billcoderule a
 left join t_option e on a.fprojectid=e.fprojectid and a.fformatindex=e.fid
 Left OUter join t_checkproject b on a.fbilltype=b.fbilltypeid and a.fprojectval=b.ffield
 where a.fbilltypeid = @FBillTypeID and  a.FProjectID=2 and a.FClassIndex=@Index order by a.FClassIndex
 if(@FDateStr='mm/dd/yy')
 begin
 Select @FDateStr=CONVERT(varchar(50), GETDATE(), 1)
 end
 else if(@FDateStr='yy/mm/dd')
 begin
 Select @FDateStr=CONVERT(varchar(50), GETDATE(), 11)
 end
 else if(@FDateStr='yyyy/mm/dd')
 begin
 Select @FDateStr=CONVERT(varchar(50), GETDATE(), 111)
 end
  else if(@FDateStr='yy-mm-dd')
 begin
 Select @FDateStr=substring(convert(char(10),getdate(),25) ,3,8)
 end
 else if(@FDateStr='mm-dd-yy')
 begin
 Select @FDateStr=CONVERT(varchar(100), GETDATE(), 10)
 end
 else if(@FDateStr='yyyy-mm-dd')
 begin
 Select @FDateStr=CONVERT(varchar(100), GETDATE(), 23)
 end
 else if(@FDateStr='yymm')
 begin
 Select @FDateStr=substring(CONVERT(varchar(100), GETDATE(), 12),0,5)
 end
  else if(@FDateStr='mmyy')
 begin
 Select @FDateStr=REPLACE(SUBSTRING( CONVERT(varchar(100), GETDATE(), 6),4,7),' ','')
 end
 else if(@FDateStr='yy-mm')
 begin
 Select @FDateStr=replace(substring(CONVERT(varchar(100), GETDATE(), 11),0,6),'/','-')
 end
 else if(@FDateStr='mm-yy')
 begin
 Select @FDateStr=  substring(CONVERT(varchar(6) , getdate(), 112 ) ,5,2)+  '-'+ substring(CONVERT(varchar(6) , getdate(), 112 ) ,3,2)
 end
 else if(@FDateStr='yyyymmdd')
 begin
 Select @FDateStr=    Convert(varchar(10),Getdate(),112) 
 end 
 set @FBillNo=isnull(@FBillNo,'')+isnull(@FDateStr,'')
 set @FprefixAndFDateStr=isnull(@FprefixAndFDateStr,'')+isnull(@FDateStr,'')
 end
 if(@FProjectID='3')
 begin
     set  @FBillNo=isnull(@FBillNo,'')+'你大爷'
 end
   set @Index=@Index+1
 end  
      select @Fnumber=a.FProjectVal from t_billcoderule a
 left join t_option e on a.fprojectid=e.fprojectid and a.fformatindex=e.fid
 Left OUter join t_checkproject b on a.fbilltype=b.fbilltypeid and a.fprojectval=b.ffield
 where a.fbilltypeid = @FBillTypeID and  a.FProjectID=3 order by a.FClassIndex
  select @FLength=a.FLength from t_billcoderule a
 left join t_option e on a.fprojectid=e.fprojectid and a.fformatindex=e.fid
 Left OUter join t_checkproject b on a.fbilltype=b.fbilltypeid and a.fprojectval=b.ffield
 where a.fbilltypeid = @FBillTypeID and  a.FProjectID=3  order by a.FClassIndex
  if exists(select 1 from t_billcoderule where FBillTypeID = @FBillTypeID and FIsBy=1)
	  begin 
	   if exists(select 1 from  t_billcodeby  where  FBillTypeID = @FBillTypeID and FFormatChar = @FprefixAndFDateStr)
		begin
		select @Fnumber =isnull(FNumMax,0) from t_billcodeby  where  FBillTypeID = @FBillTypeID and FFormatChar = @FprefixAndFDateStr
		Update t_billcodeby set  FNumMax=FNumMax+1 where FBillTypeID = @FBillTypeID and FFormatChar = @FprefixAndFDateStr
		end 
	   else 
		begin
	    set @Fnumber = @Fnumber
	    insert into t_billcodeby(FBillTypeID,FFormatChar, FProjectVal,FNumMax) select @FBillTypeID,@FprefixAndFDateStr,FProjectVal,@Fnumber+1 from t_billcoderule where FBillTypeID = @FBillTypeID and FIsBy=1
		end
	  end
  else
	  begin
	  -----更新流水号
	  update a set FProjectVal=FProjectVal+1 from t_billcoderule a
	 left join t_option e on a.fprojectid=e.fprojectid and a.fformatindex=e.fid
	 Left OUter join t_checkproject b on a.fbilltype=b.fbilltypeid and a.fprojectval=b.ffield
	 where a.fbilltypeid = @FBillTypeID and a.FProjectID=3  ---更新单号
	  end
 set @Fnumber='0000000000000'+@Fnumber
 set @Fnumber=right(@Fnumber,@FLength) --流水号
 set  @FBillNo = REPLACE(@FBillNo,'你大爷',@Fnumber)
    
commit tran 
return;
--------------存在错误
if(0<>@@error)
	goto error1
--------------回滚事务	
error1:
	rollback tran;
--------------结束存储过程
end



 