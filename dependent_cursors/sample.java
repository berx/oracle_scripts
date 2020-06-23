import java.sql.*;  
import java.util.Properties;
// set classpath=C:\...\jdbc\ojdbc10-full\ojdbc10.jar;.;  
class sample{  
  public static void main(String args[]){  
    try{  
      Class.forName("oracle.jdbc.driver.OracleDriver");  
        
      Properties properties = new Properties();
	  properties.put("user", "trc");
      properties.put("password", "trc");
      properties.put("defaultRowPrefetch", "1");
	  
 
      Connection con=DriverManager.getConnection(  
      "jdbc:oracle:thin:@localhost:1521/pdb1",properties);  
      
	  con.setAutoCommit (false);
	  
	  Statement stmt_trace=con.createStatement();
	  ResultSet rs_trace=stmt_trace.executeQuery("alter session set events '10046 trace name context forever, level 12'");
	  rs_trace.close();
	  stmt_trace.close();
	  
      Statement stmt1=con.createStatement();  
      ResultSet rs1=stmt1.executeQuery("select * from table(bla.get_date())");  
	  
	  rs1.next();
	  System.out.println(rs1.getString(1));        

	  rs1.next();
	  System.out.println(rs1.getString(1));        


      Statement stmt2=con.createStatement();  
      ResultSet rs2=stmt2.executeQuery("select * from table(bla.get_date()) T");  

	  rs2.next();
	  System.out.println(rs2.getString(1));        

	  Thread.sleep(2222);
	  
	  rs1.next();
	  System.out.println(rs1.getString(1));        

	  rs1.close();
	  stmt1.close();

	  rs2.close();
	  stmt2.close();
	  
	  con.rollback();
	  
	  Thread.sleep(3333);
	  
      con.close();  
      
    }catch(Exception e){ System.out.println(e);}  
    
  }  
}  