csvbash > sample.s 2> /dev/null  
red='\033[0;31m'
green='\033[0;32m'
NC='\033[0m' # No Color
echo -e ${red} "Pinging..."
while IFS=, read col1 col2 
do
    count=$( ping -c 1 $col1 | grep icmp* | wc -l )

    if [ $count -eq 0 ]
      then

    echo $col1 "is not Alive!"


    fi

done < LocationsImportSample.csv