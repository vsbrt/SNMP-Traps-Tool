<html>
<meta http-equiv= refresh content=10> 
<body><p><a href= detail.php?>SNMP Trap Sender</a></p>

<table border = 10>

<?php
$array=array(parse_ini_file("../db.conf"));
$dbhost = $array[0]['IP'];
$port = $array[0]['Port'];
$data = $array[0]['DBname'];
$userid = $array[0]['Username'];
$pwd = $array[0]['Password'];

 $con=mysqli_connect($dbhost,$userid,$pwd , $data, $port) ;
$result = mysqli_query($con,"SELECT * FROM Trapo"); 
echo "<table border='10'>
<tr>
<th>IP</th>
<th>STATUS</th>
</tr>";
while($row = mysqli_fetch_array($result))
{echo "<tr>";
  echo "<td>" . $row['Message'] . "</td>";
  echo "<td>" . $row['STATUS'] . "</td>";
 echo "</tr>";
  }echo "</table>";

?> 
</table>
</html>
