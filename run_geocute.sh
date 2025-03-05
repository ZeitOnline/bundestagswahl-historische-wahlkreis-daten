for name in shapes_historical/*.geojson; do \
   year=$(basename -s .geojson $name | sed 's/wkr//')
   echo "run geocute for $year ($name)"
   if [[ "$year" =~ ^[0-9]+$ ]] && [[ "$year" -le 1989 ]]; then
      geocute \
         $name id \
         shapes_2025/wkr2025_ohne_osten.geojson wkr_id \
         zensus-2022-geocute-pointcloud.bin.br \
         geocute_results/geocuted_${year}_2025.tsv;
   else
      geocute \
         $name id \
         shapes_2025/wkr2025.geojson wkr_id \
         zensus-2022-geocute-pointcloud.bin.br \
         geocute_results/geocuted_${year}_2025.tsv;
   fi
done;
