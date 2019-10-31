To deploy these scripts to the ESP watershed, copy both the "scripts" and "shared" folder into the watershed's
  base directory (i.e., where the watershed's shared and scripts folders are located).  This will copy the data into the
  correct folders.
Next, open the watershed in the CAVI and add the "Download_ESP_5mins" and "Flow_Modifier" scripts to the "Modeling" tab.

The to download and route ESP traces scripts should be ran in sequence:
	"Download_ESP_5mins"	- downloads data from NWRFC website (it takes about 5 minutes to run)
	"Flow_Modifier"		- computes local ESP traces (for Lower Snake; the 'shared/flow_eqn_config_lsr_fullrouting.csv' is specific to the Lower Snake)


Add the save_to_sql script to the scripts in your CAVI model and add the script to the end of the model sequence

You'll also need to add the 'sqlitejdbc-0.5.4.jar' jar file to your CAVI install under <CAVI install>/CAVI/jar