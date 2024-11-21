plt_logo=37
plt_txt=31
plt_subtxt=32
plt_reset=37

banner="{logo}               ..                                           
{logo}           .;oOXKxc'                                        
{logo}        'cxKNKxyyOXN0d:.                                    
{logo}    .:d0NXOo;'    ' :d0NXkl,.                               
{logo}   '0WMWO;           .lKMMWd.                               
{logo}   :NWXKN0d:.     .,lkXNKNMO. {text}oOOdoxo.  okdoxo   ,xOx  ,kO.   
{logo}   :NNf'.oONXOo;:d0NXkl,'xMO. {text}OMM  XWl  0X   XM ,lXWWd'kWW0'  
{logo}   :NN:    'cxXMW0o;.   .xMO. {text}OMM0kNK   0M0xOk  ucK0XX000N0'  
{logo}   :NN:       oWK;      .xMO. {text}OMM  XMd  0Mf     icK NxMN N0i  
{logo}   :NN:       lWK,      .xMO. {text}d00xokxb  d0:     Lx   vf  xzJ  
{logo}   ;XW0c.     lWK,     .;BMk.                               
{logo}    ,oONN0o;. lWK, ,;xKNKxc.          {subtext}Bash Package          
{logo}       .:dKNXk0MNOONXOo;.                {subtext}Manager            
{logo}          .,lkXWW0d:.                                       
{logo}              .;,.                                          {}"

banner=$(sed "s@{logo}@\\\e\[${plt_logo}m@g" <<< "$banner")
banner=$(sed "s@{text}@\\\e\[${plt_txt}m@g" <<< "$banner")
banner=$(sed "s@{subtext}@\\\e\[${plt_subtxt}m@g" <<< "$banner")
banner=$(sed "s@{}@\\\e\[${plt_reset}m@g" <<< "$banner")

echo -e "$banner"
