function [data2] = standard(data)
%STANDARD Standardizes each column of the input matrix (subtracts mean, divides by std)
   data2 = data;
   j = 1;
   while j <= size(data,2)              
      dataj = data(:,j);              
      datajm = mean(dataj);         
      datajst = std(dataj);         
      i = 1;                      
      while i <= size(data,1)         
         if data(i,j) ~= 99999
            data2(i,j) = (data(i,j) - datajm) / datajst; 
         end
         i = i + 1;
      end
      j = j + 1;                           
   end
end