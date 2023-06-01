// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../../GridHelper.sol";
import "../../CommonSVG.sol";

library CharacterCSS1 {
  string internal constant PART = "@keyframes char-s-path3_c_o{0%,10%,to{opacity:.3}10.85%,99%{opacity:0}}@keyframes char-u-c-stick-a-3_tr__tr{0%,10%,to{transform:translate(550.3px,384.48px) rotate(0deg)}15.35%,16.1%{transform:translate(550.3px,384.48px) rotate(-123.442273deg)}15.7%{transform:translate(550.3px,384.48px) rotate(-126.299482deg)}95.4%{transform:translate(550.3px,384.48px) rotate(-123.442273deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes char-u-shadow_c_o{0%,10%,to{opacity:.3}10.35%{opacity:0}99%{opacity:0;animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes char-u-c-stick-b-3_tr__tr{0%,10%,to{transform:translate(544.844405px,377.77px) rotate(0deg)}14.5%,16%{transform:translate(544.844405px,377.77px) rotate(-.323882deg)}96%{transform:translate(544.844405px,377.77px) rotate(-.323882deg);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes char-u-stick-b_to__to{0%,10%,14.5%,16%,to{transform:translate(542.410311px,377.756241px)}96%{transform:translate(542.410311px,377.756241px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes char-u-stick-b_tr__tr{0%,10%,to{transform:rotate(0deg)}14.5%,16%{transform:rotate(-132.571795deg)}96%{transform:rotate(-132.571795deg);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes char-u-stick-a_tr__tr{0%,10%,to{transform:translate(551.56866px,382.54284px) rotate(.730093deg)}14.5%,16%{transform:translate(551.56866px,382.54284px) rotate(-132.077421deg)}96%{transform:translate(551.56866px,382.54284px) rotate(-132.077421deg);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes char-u-handle_to__to{0%,10%{offset-distance:0}14.5%{offset-distance:49.746315%}16%{offset-distance:49.753576%}96%{offset-distance:50.140277%;animation-timing-function:cubic-bezier(0,0,.58,1)}to{offset-distance:100%}}@keyframes char-s-path14_c_o{0%,12.25%,12.95%,to{opacity:1}12.6%{opacity:0}}@keyframes char-s-polygon13_c_o{0%,11.8%,12.45%,to{opacity:1}12.15%{opacity:0}}@keyframes char-s-polygon14_c_o{0%,11.3%,12%,to{opacity:1}11.65%{opacity:0}}@keyframes char-s-polygon15_c_o{0%,10.8%,11.5%,to{opacity:1}11.15%{opacity:0}}@keyframes char-s-polygon16_c_o{0%,10.3%,11%,to{opacity:1}10.65%{opacity:0}}@keyframes char-s-path15_c_o{0%,10.55%,9.85%,to{opacity:1}10.2%{opacity:0}}@keyframes char-s-path17_c_o{0%,10.55%,10.85%,to{opacity:1}10.7%{opacity:0}}@keyframes char-s-path18_c_o{0%,10.05%,10.35%,to{opacity:1}10.2%{opacity:0}}@keyframes char-s-path19_c_o{0%,10.85%,11.15%,to{opacity:1}11%{opacity:0}}@keyframes char-s-path20_c_o{0%,10.35%,10.65%,to{opacity:1}10.5%{opacity:0}}@keyframes char-s-path21_c_o{0%,11.75%,12.05%,to{opacity:1}11.9%{opacity:0}}@keyframes char-s-path22_c_o{0%,12.05%,12.35%,to{opacity:1}12.2%{opacity:0}}@keyframes char-s-path23_c_o{0%,11.15%,11.45%,to{opacity:1}11.3%{opacity:0}}@keyframes char-s-path24_c_o{0%,12.35%,12.65%,to{opacity:1}12.5%{opacity:0}}@keyframes char-s-path25_c_o{0%,11.45%,11.75%,to{opacity:1}11.6%{opacity:0}}@keyframes char-u-d-u-c-stick-a_tr__tr{0%,10%{transform:translate(583.2px,526.7px) rotate(0deg)}12.35%,12.8%,to{transform:translate(583.2px,526.7px) rotate(-119.593616deg)}12.55%{transform:translate(583.2px,526.7px) rotate(-123.748374deg)}}@keyframes char-u-arm2_to__to{0%,9.65%{transform:translate(477.832954px,498.329973px)}9.9%{transform:translate(471.54724px,496.901402px)}9.95%{transform:translate(469.690097px,496.615688px)}10%{transform:translate(485.832954px,496.329973px)}11.45%{transform:translate(485.832954px,504.329973px)}11.95%{transform:translate(485.832954px,511.329973px)}15.7%,to{transform:translate(484.832954px,511.329973px)}}@keyframes char-u-arm2_tr__tr{0%,9.45%{transform:rotate(34.801984deg)}10%{transform:rotate(17.529523deg)}14.85%,to{transform:rotate(38.752383deg)}}@keyframes char-u-fore_to__to{0%,9.45%{offset-distance:0}9.5%{offset-distance:8.485488%}9.55%{offset-distance:13.875651%}9.6%{offset-distance:16.646556%}9.7%{offset-distance:23.752717%}9.8%{offset-distance:30.099326%}9.85%{offset-distance:34.477881%}9.9%{offset-distance:38.715727%}10%{offset-distance:47.25831%}11.45%{offset-distance:53.831087%}12.5%{offset-distance:60.255991%}14.85%{offset-distance:75.12091%}15.5%{offset-distance:81.804403%}16.15%{offset-distance:95.530847%}16.45%,to{offset-distance:100%}}@keyframes char-u-fore_tr__tr{0%,10%{transform:rotate(7.820979deg)}12.5%{transform:rotate(9.169017deg)}14.85%{transform:rotate(82.898499deg)}16.45%,to{transform:rotate(163.611614deg)}}@keyframes char-u-fore_ts__ts{0%,10%{transform:scale(1,1.049657)}12.5%,to{transform:scale(1,.820158)}}@keyframes char-u-d-u-hand-1_to__to{0%,9.45%{offset-distance:0}10%{offset-distance:42.851295%}14.85%{offset-distance:71.15203%}15.7%{offset-distance:82.368907%}16.45%,to{offset-distance:100%}}@keyframes char-u-d-u-hand-1_tr__tr{0%,10%,14.85%{transform:rotate(0deg)}15.7%,to{transform:rotate(53.611436deg)}}@keyframes char-u-c-arm-back-2_ts__ts{0%,16.5%,9.45%,to{transform:translate(486.216141px,567.455429px) scale(1,1)}16.45%,9.6%{transform:translate(486.216141px,567.455429px) scale(0,0)}}@keyframes char-u-c-legl_to__to{0%,11%,44%,45.5%,60%,61%,62.5%,63%,64.5%,69%,70.5%,71%,72.5%,73%,74.5%,9.5%,to{transform:translate(479.740001px,639.74px)}45%,62%,64%,70%,72%,74%{transform:translate(479.740001px,629.74px)}}@keyframes char-u-c-legl_tr__tr{0%,45%,to{transform:rotate(2.558388deg)}30%{transform:rotate(2.558388deg);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes char-u-c-body_to__to{0%,10%,15%,25%,30%,40%,45%,55%,60%,70%,75%,85%,90%,97%,to{transform:translate(463.107635px,563.06868px)}21%,36%,51%,6%,66%,81%,93%{transform:translate(464.107635px,562.06868px)}32.5%{transform:translate(459.524302px,562.652013px)}}@keyframes char-u-c-body_ts__ts{0%,15%,30%,45%,60%,75%,90%,to{transform:rotate(-1.385994deg) scale(1,1)}10%{transform:rotate(-1.385994deg) scale(1.03,1.03)}12%,25%,40%,55%,70%,85%,97%{transform:rotate(-1.385994deg) scale(1.01,1.01)}21%,36%,51%,66%,81%,93%{transform:rotate(-1.385994deg) scale(1.02,1.02)}}@keyframes char-u-c-arm-front_tr__tr{0%,50%,70%,9.2%,to{transform:translate(425.57px,513.8px) rotate(0deg)}18.5%,25%,35%,45%,5%,55%{transform:translate(425.57px,513.8px) rotate(1.309671deg)}9.5%{transform:translate(425.57px,513.8px) rotate(5.512726deg)}15%{transform:translate(425.57px,513.8px) rotate(18.701215deg)}16.5%{transform:translate(425.57px,513.8px) rotate(-3.984244deg)}30%{transform:translate(425.57px,513.8px) rotate(0deg);animation-timing-function:cubic-bezier(.42,0,1,1)}32.5%,44%{transform:translate(425.57px,513.8px) rotate(-3.509326deg)}}@keyframes char-u-head_tr__tr{0%,32.5%,9.5%,to{transform:translate(465.87996px,494.771014px) rotate(0deg)}10.5%{transform:translate(465.87996px,494.771014px) rotate(8.977152deg)}30%{transform:translate(465.87996px,494.771014px) rotate(8.977152deg);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes char-u-eyes_to__to{0%,to{transform:translate(467.739991px,458.809998px)}}@keyframes char-u-eyes_ts__ts{0%,41.5%,41.95%,5%,5.45%,to{transform:scale(1,1)}41.7%,5.2%{transform:scale(0,0)}15%{transform:scale(.95,.95)}}@keyframes char-s-g8_to__to{0%,32.5%,to{transform:translate(465.625061px,491.849991px)}9.5%{transform:translate(464.625061px,491.849991px)}10.5%,30%{transform:translate(467.625061px,491.849991px)}}@keyframes char-s-g10_to__to{0%,10%,15%,25%,26.95%,30%,40%,45%,55%,60%,70%,75%,85%,90%,97%,to{transform:translate(463.107635px,563.06868px)}21%,36%,51%,6%,66%,81%,93%{transform:translate(464.107635px,562.06868px)}32.5%{transform:translate(459.524302px,562.652013px)}}@keyframes char-s-g10_ts__ts{0%,15%,30%,45%,60%,75%,90%,to{transform:scale(1,1)}10%,21%{transform:scale(1.06,1.06)}12%,25%,40%,55%,70%,85%,97%{transform:scale(1.01,1.01)}36%,51%,66%,81%,93%{transform:scale(1.04,1.04)}}@keyframes char-u-sitting-remote_tr__tr{0%,to{transform:translate(475.309958px,605.49147px) rotate(22.437426deg)}5%,97%{transform:translate(475.309958px,605.49147px) rotate(9.369347deg)}45%,8%,95%{transform:translate(475.309958px,605.49147px) rotate(0deg)}34%,76%{transform:translate(475.309958px,605.49147px) rotate(2.603104deg)}}@keyframes char-u-c-thumb-e_tr__tr{0%,8%,97%,to{transform:translate(522.65px,622.87px) rotate(-112.759933deg)}11%,95%{transform:translate(522.65px,622.87px) rotate(0deg)}}@keyframes char-s-path69_to__to{0%,10%,96%,to{transform:translate(531.82251px,630.056854px)}11%,95%{transform:translate(531.82251px,632.056854px)}}@keyframes char-u-c-thumb-e-o_tr__tr{0%,8%,97%,to{transform:translate(522.65px,622.87px) rotate(-112.759933deg)}11%,95%{transform:translate(522.65px,622.87px) rotate(0deg)}}@keyframes char-u-c-body-e_ts__ts{0%,15%,30%,47%,60%,79%,92%{transform:translate(450.717392px,726.131329px) scale(1,1);animation-timing-function:cubic-bezier(.47,0,.745,.715)}20%,35%,5%,50%,65%,82%,95%{transform:translate(450.717392px,726.131329px) scale(1.02,1.02)}to{transform:translate(450.717392px,726.131329px) scale(1,1)}}@keyframes char-u-l-legl-e_to__to{0%,33%,34%,79%,80%,81%,82%,83%,84%,85.5%,to{transform:translate(510.43808px,717.235748px)}33.5%,79.5%,80.5%,81.5%,82.5%,83.5%{transform:translate(510.355484px,713.2366px)}84.5%{transform:translate(510.396782px,715.236174px)}}@keyframes char-u-l-legr-e_to__to{0%,15%,16.5%,to{transform:translate(468.993149px,737.905731px)}16%{transform:translate(470.993149px,729.905731px)}}@keyframes char-u-l-legr-e_tk__tk{0%,10%,24%,to{transform:skewX(0deg) skewY(0deg)}11%,23%{transform:skewX(2deg) skewY(0deg)}}@keyframes char-u-shadow-18_to__to{0%,15%,16.5%,to{transform:translate(434.264999px,682.483337px)}16%{transform:translate(433.264999px,683.483337px)}}@keyframes char-u-shadow-18_ts__ts{0%,15%,16.5%,to{transform:scale(1,1)}16%{transform:scale(1,.985124)}}@keyframes char-u-c-arm-front-e-g_tr__tr{0%,32%,35%,72%,75%,76%,79%,95%,98%,to{transform:translate(399.422592px,625.091742px) rotate(0deg)}32.5%,34.5%,72.5%,74.5%,76.5%,78.5%,95.5%,97.5%{transform:translate(399.422592px,625.091742px) rotate(-1.520694deg)}}@keyframes char-u-fingers_ts__ts{0%,35%,43%,to{transform:translate(397.700699px,691.595856px) scale(1,1)}37%,40%{transform:translate(397.700699px,691.595856px) scale(1.04,1)}}@keyframes char-s-rect7_to__to{0%,48%,7.5%,to{transform:translate(440.865005px,573.959991px)}7.9%{transform:translate(444.513117px,556.881018px)}10.5%,8%{transform:translate(443.554628px,558.901241px)}12.8%,47%{transform:translate(443.616575px,561.900602px)}}@keyframes char-s-rect7_ts__ts{0%,3%,41.45%,42.45%,to{transform:scale(1,1)}1.5%,39.95%,4%{transform:scale(1,1);animation-timing-function:cubic-bezier(.42,0,1,1)}2.5%,40.95%{transform:scale(1,0)}3.5%,41.95%{transform:scale(1,1.1);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes char-s-rect8_to__to{0%,48%,7.5%,to{transform:translate(449.205002px,573.550018px)}7.9%{transform:translate(451.853327px,556.491694px)}10.5%,8%{transform:translate(451.894625px,558.491268px)}12.8%,47%{transform:translate(451.935923px,560.490842px)}}@keyframes char-s-rect8_ts__ts{0%,3%,41.45%,42.45%,to{transform:scale(1,1)}1.5%,39.95%,4%{transform:scale(1,1);animation-timing-function:cubic-bezier(.42,0,1,1)}2.5%,40.95%{transform:scale(1,0)}3.5%,41.95%{transform:scale(1,1.1);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes char-u-c-arm-back-d_ts__ts{0%,16.15%,9.5%,to{transform:translate(494.994965px,561.592194px) scale(1,1)}15.9%,9.8%{transform:translate(494.994965px,561.592194px) scale(0,0)}}@keyframes char-u-c-arm-back-d_c_o{0%,16.15%,9.5%,to{opacity:1}16.05%,9.65%{opacity:0}}@keyframes char-u-c-legr-d_to__to{0%,15%,37.5%,to{transform:translate(462.554626px,624.175px)}15.5%,37%{transform:translate(463.554626px,617.175px)}16%,36.5%{transform:translate(465.554626px,624.175px)}}@keyframes char-u-c-legl-d_to__to{0%,16%,17%,35.5%,36.5%,to{transform:translate(491.963165px,679.705933px)}16.5%,36%{transform:translate(494.963165px,673.705933px)}}@keyframes char-u-c-body-d_ts__ts{0%,15%,30%,45%,60%,75%,90%,to{transform:translate(476.276337px,481.240997px) scale(1,1)}21%,51%,6%{transform:translate(476.276337px,481.240997px) scale(1.03,1.03)}10%,25%,40%,55%,70%,85%,97%{transform:translate(476.276337px,481.240997px) scale(1.01,1.01)}36%{transform:translate(476.276337px,481.240997px) scale(1.04,1.04)}66%,81%,93%{transform:translate(476.276337px,481.240997px) scale(1.02,1.02)}}@keyframes char-u-c-arm-front-d_tr__tr{0%,15%,30%,45%,60%,75%,90%,to{transform:translate(435.68px,518.48px) rotate(0deg)}21%,36%,51%,6%,66%,81%,93%{transform:translate(435.68px,518.48px) rotate(-1.353606deg)}}@keyframes char-u-c-head-d_tr__tr{0%,15%,30%,45%,60%,75%,90%,to{transform:translate(476.276337px,500.951019px) rotate(0deg)}21%,36%,51%,6%,66%,81%,93%{transform:translate(476.276337px,500.951019px) rotate(2.273023deg)}}@keyframes char-u-c-eyes-d_to__to{0%,10.5%,9%,98%,to{transform:translate(494.680328px,462.959381px)}12%,95%{transform:translate(494.680328px,468.959381px)}}@keyframes char-u-c-eyes-d_tr__tr{0%,15%,30%,45%,60%,75%,90%,to{transform:rotate(0deg)}21%,36%,51%,6%,66%,81%,93%{transform:rotate(2.273023deg)}}@keyframes char-s-rect10_to__to{0%,50%,55%,66%,to{transform:translate(489.635677px,464.278149px)}57.5%,64.5%{transform:translate(488.635677px,467.278149px)}}@keyframes char-s-rect10_ts__ts{0%,33.4%,34.5%,36.5%,37.6%,50%,to{transform:rotate(16.249997deg) scale(1,1)}34%,37.1%{transform:rotate(16.249997deg) scale(1,.1)}}@keyframes char-s-rect11_to__to{0%,50%,55%,66%,to{transform:translate(497.462329px,464.109316px)}57.5%,64.5%{transform:translate(496.462329px,467.109316px)}}@keyframes char-s-rect11_ts__ts{0%,33.4%,34.5%,36.5%,37.6%,50%,to{transform:rotate(16.249997deg) scale(1,1)}34%,37.1%{transform:rotate(16.249997deg) scale(1,.1)}}@keyframes char-s-path97_to__to{0%,55%,57%,68%,to{transform:translate(490.169983px,453.149979px)}65%{transform:translate(490.169983px,454.149979px)}}@keyframes char-s-path98_to__to{0%,55%,57%,68%,to{transform:translate(502.984619px,453.859985px)}65%{transform:translate(501.984619px,454.859985px)}}@keyframes char-s-path102_to__to{0%,15%,37.5%,to{transform:translate(453.375px,748.269989px)}15.5%,37%{transform:translate(454.875px,739.269989px)}16%,36.5%{transform:translate(456.375px,746.269989px)}}@keyframes char-s-path103_to__to{0%,16%,17%,35.5%,36.5%,to{transform:translate(482.005005px,733.149994px)}16.5%,36%{transform:translate(486.005005px,726.149994px)}}@keyframes char-u-c-head-b_to__to{0%,16.95%,17.4%,17.5%,17.95%,21%,21.45%,21.55%,22%,42%,42.45%,42.55%,43%,67%,67.45%,67.55%,68%{transform:translate(568.928925px,674.769501px)}17.25%,17.7%,17.8%,18.25%,21.3%,21.75%,21.85%,22.3%,42.3%,42.75%,42.85%,43.3%,67.3%,67.75%,67.85%,68.3%,to{transform:translate(568.928925px,673.769501px)}}@keyframes char-s-g15_ts__ts{0%,21%,22.5%,23%,24.5%,54.5%,56%,to{transform:translate(571.438171px,664.179993px) scale(1,1)}21.5%,23.5%,55%{transform:translate(571.438171px,664.179993px) scale(.1,.1)}}@keyframes char-s-g16_ts__ts{0%,21%,22.5%,23%,24.5%,54.5%,56%,to{transform:translate(576.028137px,669.410034px) scale(1,1)}21.5%,23.5%{transform:translate(576.028137px,669.410034px) scale(.1,.1)}55%{transform:translate(576.028137px,669.410034px) scale(.2,.2)}}@keyframes char-u-c-arm-back-b_tr__tr{0%,10%,12%,22%,24%,34%,36%,46%,48%,58%,60%,70%,72%,82%,84%,98%,to{transform:translate(522.093055px,676.27px) rotate(0deg)}5%{transform:translate(522.093055px,676.27px) rotate(-2.048741deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}17%,29%,41%,53%,65%,77%,93%{transform:translate(522.093055px,676.27px) rotate(-1.157215deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes char-u-c-body-b_ts__ts{0%,36%,72%{transform:translate(517.902943px,736.775px) scale(1,1);animation-timing-function:cubic-bezier(.42,0,.58,1)}26%,67%,93%{transform:translate(517.902943px,736.775px) scale(.961813,1.05)}34%,70%,98%,to{transform:translate(517.902943px,736.775px) scale(1,1)}}@keyframes char-u-c-legr-b_tr__tr{.55%,0%,1.1%,1.5%,1.9%,15%,15.55%,16.1%,16.5%,16.9%,19%,19.55%,20.1%,20.5%,20.9%,40%,40.55%,41.1%,41.5%,41.9%,65%,65.55%,66.1%,66.5%,66.9%,to{transform:translate(437.92px,741.18px) rotate(0deg)}.3%,.85%,1.25%,1.65%,15.3%,15.85%,16.25%,16.65%,19.3%,19.85%,20.25%,20.65%,40.3%,40.85%,41.25%,41.65%,65.3%,65.85%,66.25%,66.65%{transform:translate(437.92px,741.18px) rotate(.618911deg)}}@keyframes char-u-c-legl-b_tr__tr{.85%,0%,1.4%,15%,15.85%,16.4%,19%,19.85%,20.4%,45.15%,46%,46.55%,63%,63.55%,64.1%,64.5%,64.9%,to{transform:translate(463.461823px,762.505px) rotate(0deg)}.3%,1.05%,1.75%,15.3%,16.05%,16.75%,19.3%,20.05%,20.75%,45.45%,46.2%,46.9%{transform:translate(463.461823px,762.505px) rotate(.719478deg)}.55%,1.25%,1.85%,15.55%,16.25%,16.85%,19.55%,20.25%,20.85%,45.7%,46.4%,47%{transform:translate(463.461823px,762.505px) rotate(.191674deg)}63.3%,63.85%,64.25%,64.65%{transform:translate(463.461823px,762.505px) rotate(.618911deg)}}@keyframes char-u-c-arm-front-b_tr__tr{0%,10%,12%,22%,24%,34%,36%,46%,48%,58%,60%,70%,72%,82%,84%,98%,to{transform:translate(568.937836px,711.765257px) rotate(0deg)}17%,29%,41%,5%,53%,65%,77%,93%{transform:translate(568.937836px,711.765257px) rotate(-1.157215deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes char-u-c-clothes-degraded-a_ts__ts{0%,36%,72%{transform:translate(441.770004px,748.225006px) scale(1,1);animation-timing-function:cubic-bezier(.42,0,.58,1)}26%,67%,93%{transform:translate(441.770004px,748.225006px) scale(.961813,1.05)}34%,70%,98%,to{transform:translate(441.770004px,748.225006px) scale(1,1)}}@keyframes char-u-shadow-19_ts__ts{0%{transform:translate(457.878357px,758.504608px) scale(1,1);animation-timing-function:cubic-bezier(.555,.005,.4,.98)}15%,47%,80%{transform:translate(457.878357px,758.504608px) scale(.8,.8);animation-timing-function:cubic-bezier(.555,.005,.4,.98)}31%,63%{transform";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";

library GridHelper {
  uint256 public constant MAX_GRID_INDEX = 8;

  /**
    * @dev slice array of bytes
    * @param data The array of bytes to slice
    * @param start The start index
    * @param len The length of the slice
    * @return The sliced array of bytes
   */

  function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
      bytes memory b = new bytes(len);
      for (uint256 i = 0; i < len; i++) {
        b[i] = data[i + start];
      }
      return b;
  }

  /**
    * @dev combine two arrays of strings
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineStringArrays(string[] memory a, string[] memory b) public pure returns (string[] memory) {
    string[] memory c = new string[](a.length + b.length);
    for (uint256 i = 0; i < a.length; i++) {
        c[i] = a[i];
    }
    for (uint256 i = 0; i < b.length; i++) {
        c[i + a.length] = b[i];
    }
    return c;
  }

  /**
    * @dev combine two arrays of uints
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineUintArrays(uint256[] memory a, uint256[] memory b) public pure returns (uint256[] memory) {
      uint256[] memory c = new uint256[](a.length + b.length);
      for (uint256 i = 0; i < a.length; i++) {
          c[i] = a[i];
      }
      for (uint256 i = 0; i < b.length; i++) {
          c[i + a.length] = b[i];
      }
      return c;
  }

  /**
    * @dev wrap a string in a transform group
    * @param x The x position
    * @param y The y position
    * @param data The data to wrap
    * @return The wrapped string
   */

  function groupTransform(string memory x, string memory y, string memory data) internal pure returns (string memory) {
    return string.concat("<g transform='translate(", x, ",", y, ")'>", data, "</g>");
  }

  /**
    * @dev convert a uint to bytes
    * @param x The uint to convert
    * @return b The bytes
   */

  function uintToBytes(uint256 x) internal pure returns (bytes memory b) {
      b = new bytes(32);
      assembly {
          mstore(add(b, 32), x)
      } //  first 32 bytes = length of the bytes value
  }

  /**
    * @dev convert bytes with length equal to bytes32 to uint
    * @param value The bytes to convert
    * @return The uint
   */

  function bytesToUint(bytes memory value) internal pure returns(uint) {
    uint256 num = uint256(bytes32(value));
    return num;
  }

  /**
    * @dev convert bytes with length less than bytes32 to uint
    * @param a The bytes to convert
    * @return The uint
   */

  function byteSliceToUint (bytes memory a) internal pure returns(uint) {
    bytes32 padding = bytes32(0);
    bytes memory formattedSlice = slice(bytes.concat(padding, a), 1, 32);

    return bytesToUint(formattedSlice);
  }

  /**
    * @dev get a byte from a random number at a given position
    * @param rand The random number
    * @param slicePosition The position of the byte to slice
    * @return The random byte
   */

  function getRandByte(uint rand, uint slicePosition) internal pure returns(uint) {
    bytes memory bytesRand = uintToBytes(rand);
    bytes memory part = slice(bytesRand, slicePosition, 1);
    return byteSliceToUint(part);
  }

  /**
    * @dev convert a string to a uint
    * @param s The string to convert
    * @return The uint
   */

  function stringToUint(string memory s) internal pure returns (uint) {
      bytes memory b = bytes(s);
      uint result = 0;
      for (uint256 i = 0; i < b.length; i++) {
          uint256 c = uint256(uint8(b[i]));
          if (c >= 48 && c <= 57) {
              result = result * 10 + (c - 48);
          }
      }
      return result;
  }

  /**
    * @dev repeat an object a given number of times with given offsets
    * @param object The object to repeat
    * @param times The number of times to repeat
    * @param offsetBytes The offsets to use
    * @return The repeated object
   */

  function repeatGivenObject(string memory object, uint times, bytes memory offsetBytes) internal pure returns (string memory) {
    // uint sliceSize = offsetBytes.length / (times * 2); // /2 for x and y
    require(offsetBytes.length % (times * 2) == 0, "offsetBytes length must be divisible by times * 2");
    string memory output = "";
    for (uint256 i = 0; i < times; i++) {
      string memory xOffset = string(slice(offsetBytes, 2*i * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      string memory yOffset = string(slice(offsetBytes, (2*i + 1) * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      output = string.concat(
        output,
        groupTransform(xOffset, yOffset, object)
      );
    }
    return output;
  }

  /**
    * @dev convert a single string to an array of uints
    * @param values The string to convert
    * @param numOfValues The number of values in the string
    * @param lengthOfValue The length of each value in the string
    * @return The array of uints
   */

  function setUintArrayFromString(string memory values, uint numOfValues, uint lengthOfValue) internal pure returns (uint[] memory) {
    uint[] memory output = new uint[](numOfValues);
    for (uint256 i = 0; i < numOfValues; i++) {
      output[i] = stringToUint(string(slice(bytes(values), i*lengthOfValue, lengthOfValue)));
    }
    return output;
  }

  /**
    * @dev get the sum of an array of uints
    * @param arr The array to sum
    * @return The sum
   */

  function getSumOfUintArray(uint[] memory arr) internal pure returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
    return sum;
  }

  /**
    * @dev constrain a value to the range 0-255, must be between -255 and 510
    * @param value The value to constrain
    * @return The constrained value
   */

  function constrainToHex(int value) internal pure returns (uint) {
    require(value >= -255 && value <= 510, "Value out of bounds.");
    if (value < 0) { // if negative, make positive
      return uint(0 - value);
    }
    else if (value > 255) { // if greater than 255, count back from 255
      return uint(255 - (value - 255));
    } else {
      return uint(value);
    }
  }

  /**
    * @dev create an array of equal probabilities for a given number of values
    * @param numOfValues The number of values
    * @return The array of probabilities
   */

  function createEqualProbabilityArray(uint numOfValues) internal pure returns (uint[] memory) {
    uint oneLess = numOfValues - 1;
    uint[] memory probabilities = new uint[](oneLess);
    for (uint256 i = 0; i < oneLess; ++i) {
      probabilities[i] = 256 * (i + 1) / numOfValues;
    }
    return probabilities;
  }

  /**
    * @dev get a single object from a string of object numbers
    * @param objectNumbers The string of objects
    * @param channelValue The hex value of the channel
    * @param numOfValues The number of values in the string
    * @param valueLength The length of each value in the string
    * @return The object
   */

  function getSingleObject(string memory objectNumbers, uint channelValue, uint numOfValues, uint valueLength) internal pure returns (uint) {
    
    // create probability array assuming all objects have equal probability
    uint[] memory probabilities = createEqualProbabilityArray(numOfValues);

    uint[] memory objectNumbersArray = setUintArrayFromString(objectNumbers, numOfValues, valueLength);

    uint oneLess = numOfValues - 1;

    for (uint256 i = 0; i < oneLess; ++i) {
      if (channelValue < probabilities[i]) {
        return objectNumbersArray[i];
      }
    }
    return objectNumbersArray[oneLess];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Environment.sol";
import "./Patterns.sol";
import "./GridHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library CommonSVG {

  // opening svg start tag
  string internal constant SVG_START = "<svg xmlns='http://www.w3.org/2000/svg' shape-rendering='geometricPrecision' text-rendering='geometricPrecision' width='936' height='1080' xmlns:xlink='http://www.w3.org/1999/xlink'>";

  string internal constant DUOTONE_DEFS = "<linearGradient id='lDT' gradientTransform='rotate(45)'><stop offset='0.2' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient><linearGradient id='rDT' gradientTransform='rotate(0)'><stop offset='0.2' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient><linearGradient id='fDT' gradientTransform='rotate(90)'><stop offset='0' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient>";

  string internal constant SCRIPT = "<script type='text/javascript' href='https://demowebdevukssa2.z33.web.core.windows.net/html-svg/pocs/0311/anma.js' xlink:actuate='onLoad' xlink:show='other' xlink:type='simple' />";
  // string internal constant SCRIPT = "";

  string internal constant STYLE = "<style>";

  string internal constant TEMP_STYLE = "<style> .no-animation * { animation: none !important; transition: none !important; } </style>";

  string internal constant STYLE_CLOSE = "</style>";

  string internal constant G_START = "<g>";

  string internal constant FLIPPED = "<g style='transform:scaleX(-1);transform-origin:50% 50%;'>";

  string internal constant NOT_FLIPPED = "<g style='transform:scaleX(1);transform-origin:50% 50%;'>";

  string internal constant SHELL_OPEN = "<g style='transform:scaleX(";

  string internal constant SHELL_CLOSE = ");transform-origin:50% 50%;' id='shell' clip-path='url(#clipPathShell)' ";

  string internal constant ROTATIONS = "-40-45-45";

  // 18 colours: light, base and dark for each of the 6 gradients
  string internal constant OBJECT_GRADIENTS_IDS = "c0lc0bc0dc1lc1bc1dc2lc2bc2dc3lc3bc3dc4lc4bc4dc5lc5bc5d";

  string internal constant LIGHTEN_PERCENTAGES = "025000025"; // 25% lighter, 0% base, 25% darker

  string internal constant GRADIENT_STYLE_OPEN = "<style id='gradient-colors'> :root { ";

  string internal constant GRADIENT_STYLE_CLOSE = " } </style>";

  string internal constant GLOBAL_COLOURS = "051093072042080068328072085327073074027087076025054060000000069000000050085092060082067051051093072060088081002087076000054060000000069000000050322092060322092056322092060322092056047084056046068047000000069000000050";

  string internal constant GLOBAL_COLOURS_IDS = "g0g1g2g3g4g5g6g7";

  string internal constant SHELL_COLOUR_IDS = "s2s1s0";

  string internal constant CHARACTER_COLOUR_IDS = "r0";

  // string internal constant x = "<g id='shell-vignette' style='mix-blend-mode:normal'><rect fill='url(#vig1-u-vig1-fill)' width='1080' height='1080'/></g>";
  string internal constant VIGNETTE_GRADIENT = "<clipPath id='clipPathShell'><polygon points='0,270 468,0 936,270 936,810 468,1080 0,810'/></clipPath><radialGradient id='vig1-u-vig1-fill' cx='0' cy='0' r='0.5' spreadMethod='pad' gradientUnits='objectBoundingBox' gradientTransform='translate(0.43 0.5)'><stop id='vig1-u-vig1-fill-0' offset='50%' stop-color='#000' stop-opacity='0'/><stop id='vig1-u-vig1-fill-1' offset='100%' stop-color='#000' stop-opacity='0.3'/></radialGradient>";

  // PATTERNS
  string internal constant PATTERNS_START = "<pattern id='shell-pattern' patternUnits='objectBoundingBox' x='0' y='0' width='";

  string internal constant PATTERNS_HEIGHT = "' height='";

  string internal constant PATTERNS_SCALE_OPEN = "' patternTransform=' scale(";

  string internal constant PATTERNS_SCALE_CLOSE = ")'><use xmlns:xlink='http://www.w3.org/1999/xlink' xlink:href='#mp2-u-group-";

  string internal constant PATTERNS_END = "' id='shell-pattern-use' class='pulsateInOutOld'/></pattern>";

  string internal constant OPACITY_START = "<g id='leftWall'><polygon points='0,270 468,0 468,540 0,810' fill='url(#s0)' stroke='black'/><g id='leftWallPat' transform='skewY(-30)'><rect x='0' y='270' width='468' height='540' opacity='";

  string internal constant OPACITY_MID_ONE = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g><polygon points='0,270 468,0 468,540 0,810' fill='url(#lDT)' stroke='black'/></g><g id='rightWall'><polygon points='468,540 468,0 936,270 936,810' fill='url(#s1)' stroke='black'/><g id='rightWallPat' transform='skewY(30)'><rect x='468' y='-270' width='468' height='540' opacity='";

  string internal constant OPACITY_MID_TWO = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g><polygon points='468,540 468,0 936,270 936,810' fill='url(#rDT)' stroke='black'/></g><g id='floor'><polygon id='polygon-floor-border' points='0,810 468,1080 936,810 468,540' fill='url(#s2)' stroke='black'/><g id='floorPat' transform='translate(234 135) rotate(60)' transform-origin='0 540'><g transform='skewY(-30)' transform-origin='0 0'><rect id='floorPatRect' x='0' y='270' width='468' height='540' opacity='";

  string internal constant OPACITY_END = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g></g><polygon id='polygon-floor-border-DT' points='0,810 468,1080 936,810 468,540' fill='url(#fDT)' stroke='black'/></g>";

  function createObjectGradient(uint[6] memory colours, string memory id) internal pure returns (string memory) {
    string memory output = string.concat(
      "<linearGradient id='",
      id,
      "' x1='0%' y1='0%' x2='100%' y2='0%'><stop offset='0%' stop-color='hsl(",
      Strings.toString(colours[0]),
      ",",
      Strings.toString(colours[1]),
      "%,"
    );

    output = string.concat(
      output,
      Strings.toString(colours[2]),
      "%)'/><stop offset='100%' stop-color='hsl(",
      Strings.toString(colours[3]),
      ",",
      Strings.toString(colours[4]),
      "%,",
      Strings.toString(colours[5]),
      "%)'/></linearGradient>"
    );

    return output;
  }

  function appendToGradientStyle(string memory gradientStyle, string memory id, uint h, uint s, uint l) internal pure returns (string memory) {
    return string.concat(
      gradientStyle,
      "--",
      id,
      ": hsl(",
      Strings.toString(h),
      ",",
      Strings.toString(s),
      "%,",
      Strings.toString(l),
      "%); "
    );
  }

  function getshellColours(string memory machine, uint colourValue) external pure returns(string memory) {
    uint[] memory baseColours = Environment.getColours(machine, colourValue); // 12 colours, 3 values for each

    string memory gradientStyle = GRADIENT_STYLE_OPEN;
    // uint[] memory lightenBy = GridHelper.setUintArrayFromString(LIGHTEN_PERCENTAGES, 3, 3);
    string[] memory objectGradients = new string[](18);
    for (uint i = 0; i < 6; ++i) {
      for (uint j = 0; j < 3; ++j) {
        objectGradients[i*3+j] = createObjectGradient([baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2], baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]], string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)));
        if (j == 1) {
          gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)), baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2]);
        } else {
          gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)), baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]);
        }
      }
    }

    // SHELL COLOURS
    string[] memory shellColours = new string[](3);
    for (uint i = 0; i < 3; ++i) {
      shellColours[i] = createObjectGradient([baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2], baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]], string(GridHelper.slice(bytes(SHELL_COLOUR_IDS), i*2, 2)));
    }

    // GLOBAL COLOURS
    uint[] memory globalColours = GridHelper.setUintArrayFromString(GLOBAL_COLOURS, 72, 3);
    uint globalOffset = 0;
    if (colourValue > 170) {
      globalOffset = 48;
    } else if (colourValue > 84) {
      globalOffset = 24;
    }
    for (uint i = 0; i < 8; ++i) {
      gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(GLOBAL_COLOURS_IDS), i*2, 2)), globalColours[i*3+globalOffset], globalColours[i*3+1+globalOffset], globalColours[i*3+2+globalOffset]);
    }

    // CHARACTER COLOURs
    gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(CHARACTER_COLOUR_IDS), 0, 2)), baseColours[0], baseColours[1], 90);

    gradientStyle = string.concat(gradientStyle, GRADIENT_STYLE_CLOSE);

    string memory returnDefs = string.concat(
      gradientStyle,
      "<defs>",
      VIGNETTE_GRADIENT,
      DUOTONE_DEFS
    );

    for (uint i = 0; i < 18; ++i) {
      returnDefs = string.concat(returnDefs, objectGradients[i]);
    }

    for (uint i = 0; i < 3; ++i) {
      returnDefs = string.concat(returnDefs, shellColours[i]);
    }

    returnDefs = string.concat(returnDefs, "</defs>");

    return returnDefs;
  }

  function createShellPattern(uint rand, int baseline) external pure returns(string memory) {
    return string.concat(
      PATTERNS_START,
      "0.330", // width
      PATTERNS_HEIGHT,
      "0.330", // height
      PATTERNS_SCALE_OPEN,
      Patterns.getScale(rand, baseline),
      PATTERNS_SCALE_CLOSE,
      Patterns.getPatternName(rand, baseline),
      PATTERNS_END
    );
  }

  function createShellOpacity(uint rand, int baseline) external pure returns(string memory) {
    return string.concat(
      OPACITY_START,
      Patterns.getOpacity(rand, baseline, 0),
      OPACITY_MID_ONE,
      Patterns.getOpacity(rand, baseline, 1),
      OPACITY_MID_TWO,
      Patterns.getOpacity(rand, baseline, 2),
      OPACITY_END
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./GridHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Environment {
  uint internal constant TOTAL_BASIC_COLOURS = 5;
  uint internal constant TOTAL_EMBELLISHED_COLOURS = 6;
  uint internal constant TOTAL_DEGRADED_COLOURS = 8; // includes grey

  // LW, RW, FLOOR
  string internal constant EXECUTIVE_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant LAB_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant FACTORY_COLOUR_PERCENTAGES = "040020025000070000";

  // Darker Gray, Orange, Dark Gray, Red, Light Gray, Orange, Lightest Gray, Red
  string internal constant EXECUTIVE_DEGRADED_HSL = "120001015120001035120001061120002088019068078019032045019058048002047049";
  string internal constant LAB_DEGRADED_HSL = "120001015120001035120001061120002088156015049050047054276021058155037049";
  string internal constant FACTORY_DEGRADED_HSL = "120001015120001035120001061120002088021042074203032059319029046243031039";

  // EXECUTIVE
  // Combined without shades
  string internal constant EXECUTIVE_COLOURS_BASIC = "000000069240003029000000069240003029000000069000000069240003013000000069354100060240003013000000069240003013240003029047100050240003013240003029240003013240003029121082050240003013240003029240003013240003029221082050240003013354100060000100004000100004022100050041100050047100050021081004021081004030100013022100045221081088194090077200075078195086089200084076";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED = "121082050093090004099074009095085054099075072093090004221082050194089004199074009195085054199075080194089004339082050314089004317074009313085054318075084314089004357061040040091044040091062040091044040091062040091044137093049197100052287100053347100053047100052287100053259100052184100052083100052050100050000100050083100052093063053082084048066100048053100050036100050066100048060087053061100042070100040101055042165100025070100040";
  // Combined with shades
  string internal constant EXECUTIVE_COLOURS_BASIC_SHADE = "000000050240003029000000050240003029000000050000000050240003029000000050000086027240003029000000050240003029240003013047100032240003029240003013240003029240003013104079046240003029240003013240003029240003013204079046240003029000086027000061010000100007013091043041100045047100032022080008022081012030100015022100040204079087196071077180054080195093089195095092";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED_SHADE = "104079046096071004080054015095093054095096068096071004204079046196071004180054015195093054195096068196071004322079046316071004299054015313093054313096068316071004357078056040091062040091044040091062040091044040091062168100054257100053317100053017100052047100056317100053284100052212092052155100052068100052032100050155100052093063057093068048075100048058100050047100050075100048060100062061100044065100041081077041137055037065100041";

  // LAB
  // Combined without shades
  string internal constant LAB_COLOURS_BASIC = "185053039180055056185053039180095040181066049231095074252070052231095074210049067030100050168056095228081062168056095051093072182081087240060097253081078240060097224062081245080083352033081165032066027028078027033080037031079143014078000000100143014078237045053183099034207099060207099060040090096239066051176077048221081088194090077200075078195086089200084076";
  string internal constant LAB_COLOURS_EMBELLISHED = "158100077228081062168056095051093072182081087168056095238100086253081078240060097224062081245080083253081078190054036252070052231095074210049067030100050252070052144090033040091044040091062040091044040091062040091044287100053047100052137093049347100053197100052287100053000100050050100050083100052184100052259100052083100052036100050053100050066100048082084048093063053082084048165100025101055042070100040061100042060087053070100040";
  // Combined with shades
  string internal constant LAB_COLOURS_BASIC_SHADE = "181085042184045075181085042180059062181062052251085079251073027251085079211053076030100050182081087229047032182081087051090084180064063242083093252047060242083093224058089244079072004029080164031070021030079022034081023028075143014068183100080143014068237045048183099028239066051207099060041090092238072019176077048204079087196071077180054080195093089195095092";
  string internal constant LAB_COLOURS_EMBELLISHED_SHADE = "169048056229047032182081087051090084180064063182081087241047074252047060242083093224058089244079072252047060184021040251073027251085079211053076030100050251073027147089054040091062040091044040091062040091044040091062317100053047100056168100054017100052257100053317100053032100050068100052155100052212092052284100052155100052047100050058100050075100048093068048093063057093068048137055037081077041065100041061100044060100062065100041";

  // FACTORY
  // Combined without shades
  string internal constant FACTORY_COLOURS_BASIC = "232053033232052058232054032232051037232058059196085079193083063193048054193064047193089055231032035196085079231032035300085082000000085249069060196085079231032035300085082000000085266083081162085079197031035266083081000000085033098060196085068231032035196085068000000085300085082196085079231032035033100052000000085221081088194090077200075078195086089200084076";
  string internal constant FACTORY_COLOURS_EMBELLISHED = "160073059280078043280077074340097062160071039280078043280094041340086057280084075340084055340087027340086057162085079266083081266083081197031035000000085266083081220067026040091044040091072040091044040091072040091044197100052287100053137093049347100053047100052287100053083100052050100050000100050259100052184100052050100050082084048066100048036100050053100050093063053082084048101055042070100040165100025060087053061100042070100040";
  // Combined with shades
  string internal constant FACTORY_COLOURS_BASIC_SHADE = "232066056233054034232066067232071029232091066196084068193045040193073053193067051193070044229034024193083063229034024033098060000000052243039046193083063229034024033098060000000052359097059159084063195034025266086072000000052033098044193083052229034024193083052000000052321076067193083063229034024033098060000000052204079087196071077180054080195093089195095092";
  string internal constant FACTORY_COLOURS_EMBELLISHED_SHADE = "243039046300085082193083063229034024000000052300085082249069060033098060196085079231032035000000085033098060159084063359097059266086072195034025000000052359097059220096052040091072040091044040091072040091044220087032257100053317100053168100054017100052047100056317100053155100052068100052032100050284100052212092052068100052093068048075100048047100050058100050093063057093068048081077041065100041137055037060100062061100044065100041";

  string internal constant DEGRADED_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant BASIC_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant EMBELLISHED_COLOUR_PERCENTAGES = "064115153191217237251256";

  function increaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns(uint) {
    uint value = baseLightness + (baseLightness * percentage / 100);
    if (value > 100) {
      value = 100;
    }
    return value;
  }

  function decreaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns (uint) {
    return baseLightness - (baseLightness * percentage / 100);
  }

  function getColours(string memory machine, uint baseValue) external pure returns (uint[] memory) {
    uint[] memory colourArray = new uint[](36); // 6 colours, 3*2 values each

    uint colourIndex = getColourIndex(baseValue);

    if (colourIndex < 8) { // degraded
      colourArray = getDegradedShell(colourArray, machine, baseValue);
    } else { // basic or embellished
      colourArray = getBasicEmbelishedShell(colourArray, machine, baseValue);
    }
    return colourArray;
  }

  function getColourIndex(uint baseValue) internal pure returns(uint) {
    uint[] memory colourProbabilitiesArray = GridHelper.createEqualProbabilityArray(24);

    uint index = 100;
    for (uint i = 0; i < colourProbabilitiesArray.length; ++i) {
      if (baseValue < colourProbabilitiesArray[i]) {
        index = i;
        break;
      }
    }
    if (index == 100) {
      index = 23;
    }

    return index;
  }

  function selectBasicEmbellishedPalette(string memory machine, uint baseValue) internal pure returns (string[] memory) {
    string[] memory basicPalette = new string[](2);
    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    index = index % 8;

    uint size;
    if (state == 1) {
      size = TOTAL_BASIC_COLOURS * 9;
    } else {
      size = TOTAL_EMBELLISHED_COLOURS * 9;
    }

    // could be simplified by storing every colour in a single string but this is more readable and easier to change
    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else { // factory
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    }

    return basicPalette;
  }

  function getDegradedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    string memory degradedHsl;
    string memory degradedPercentages;

    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      degradedHsl = EXECUTIVE_DEGRADED_HSL;
      degradedPercentages = EXECUTIVE_COLOUR_PERCENTAGES;
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      degradedHsl = LAB_DEGRADED_HSL;
      degradedPercentages = LAB_COLOUR_PERCENTAGES;
    } else { // factory
      degradedHsl = FACTORY_DEGRADED_HSL;
      degradedPercentages = FACTORY_COLOUR_PERCENTAGES;
    }

    uint index = getColourIndex(baseValue);
    uint[] memory singleColour = new uint[](3); // h, s, l
    for (uint i = 0; i < 3; ++i) {
      singleColour[i] = GridHelper.stringToUint(string(GridHelper.slice(bytes(degradedHsl), (index)*9 + 3*i, 3))); // 9 = h,s,l to 3 significant digits
    }
    uint[] memory colourPercentages = GridHelper.setUintArrayFromString(degradedPercentages, 6, 3);
    
    for (uint i = 0; i < 12; ++i) { // 12 = 6 colours, 2 values each
      colourArray[i*3] = singleColour[0];
      colourArray[i*3+1] = singleColour[1];
      colourArray[i*3+2] = increaseValueByPercentage(singleColour[2], colourPercentages[i%6]);
    }

    return colourArray;
  }

  function getBasicEmbelishedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    uint numColours;
    if (state == 1) {
      numColours = TOTAL_BASIC_COLOURS;
    } else {
      numColours = TOTAL_EMBELLISHED_COLOURS;
    }

    string[] memory colourAvailableStrings = selectBasicEmbellishedPalette(machine, baseValue);
    uint[] memory coloursAvailable = GridHelper.setUintArrayFromString(colourAvailableStrings[0], numColours*3, 3);
    uint[] memory coloursAvailableShade = GridHelper.setUintArrayFromString(colourAvailableStrings[1], numColours*3, 3);

    for (uint i = 0; i < 6; ++i) {
      for (uint j = 0; j < 3; ++j) { // j = h, s, l
        // Duplicate colours for linear gradient
        colourArray[2*i*3+j] = coloursAvailable[3*(i % numColours) + j];
        colourArray[(2*i+1)*3+j] = coloursAvailableShade[3*(i % numColours) + j];
      }
    }

    return colourArray;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./GridHelper.sol";
import "./Noise.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Patterns {

  // 20 to 2 inclusive in 0.5 decrements
  string internal constant ANIMATED_TEXTURE_NUMBERS = "20.019.018.017.016.015.014.013.012.011.010.09.008.007.006.005.004.003.002.00";

  // 4 to 1 inclusive in 0.1 decriments
  string internal constant TEXTURE_SCALE_NUMBERS = "4.03.93.83.73.63.53.43.33.23.13.02.92.82.72.62.52.42.32.22.12.01.91.81.71.61.51.41.31.21.11.0";

  // 15 to 0.3 inclusive in 0.3 decriments
  string internal constant PATTERNS_SCALE_NUMBERS = "15.014.714.414.113.813.513.212.912.612.312.011.711.411.110.810.510.209.909.609.309.008.708.408.107.807.507.206.906.606.306.005.705.405.104.804.504.203.903.603.303.002.702.402.101.801.501.200.900.600.3";

  string internal constant ANIMATED_TEXTURE_NAMES = "TEXT12TEXT14TEXT09TEXT10TEXT13TEXT11";

  string internal constant TEXTURE_NAMES = "TEXT04TEXT01TEXT07TEXT05TEXT08TEXT02TEXT03TEXT06";

  string internal constant PATTERNS_NAMES = "GEOM03GEOM04PIXE02AZTC10GEOM02GEOM01LOGI01GEOM05PIXE02AZTC01AZTC05AZTC03AZTC09AZTC02AZTC08AZTC04AZTC06AZTC07";

  /**
    * @dev Get if the pattern is a texture or not based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return If the pattern is a texture or not
   */

  function getIsTexture(uint rand, int baseline) public pure returns (bool) {
    uint textureDigits = GridHelper.constrainToHex(Noise.getNoiseArrayThree()[GridHelper.getRandByte(rand, 5)] + baseline);

    return textureDigits < 128;
  }

  /**
    * @dev Get the pattern name based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The pattern name
   */

  function getPatternName(uint rand, int baseline) public pure returns (string memory) {
    uint patternDigits = GridHelper.constrainToHex(Noise.getNoiseArrayThree()[GridHelper.getRandByte(rand, 5)] + baseline);

    bool isTexture = getIsTexture(rand, baseline);

    if (!isTexture) {
      patternDigits -= 128;
    }

    patternDigits *= 2;

    bool isAnimatedTexture = baseline < 70;

    uint nameLength;
    uint nameCount;
    string memory names;

    if (isAnimatedTexture) {
      nameLength = 6;
      nameCount = 6;
      names = ANIMATED_TEXTURE_NAMES;
    } else if (isTexture && !isAnimatedTexture) {
      nameLength = 6;
      nameCount = 8;
      names = TEXTURE_NAMES;
    } else {
      nameLength = 6;
      nameCount = 18;
      names = PATTERNS_NAMES;
    }

    uint[] memory nameProbabilitiesArray = GridHelper.createEqualProbabilityArray(nameCount);

    uint oneLess = nameCount - 1;

    for (uint i = 0; i < oneLess; ++i) {
      if (patternDigits < nameProbabilitiesArray[i]) {
        return string(GridHelper.slice(bytes(names), i * nameLength, nameLength));
      }
    }

    return string(GridHelper.slice(bytes(names), oneLess * nameLength, nameLength));
  }

  /**
    * @dev Get the surface quantity based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The surface quantity
   */

  function getSurfaceQuantity(uint rand, int baseline) public pure returns (bool[3] memory) {
    uint surfaceDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 6)] + baseline);

    if (baseline < 70) {
      surfaceDigits += 128; // animated textures should appear on 2+ surfaces
    }

    // LW, RW, FLOOR
    uint[] memory surfaceProbabilitiesArray = GridHelper.createEqualProbabilityArray(4);

    if (surfaceDigits < surfaceProbabilitiesArray[0]) {
      return [true, false, false];
    } else if (surfaceDigits < surfaceProbabilitiesArray[1]) {
      return [false, true, false];
    } else if (surfaceDigits < surfaceProbabilitiesArray[2]) {
      return [true, true, false];
    } else {
      return [true, true, true];
    }
  }

  /**
    * @dev Get the pattern scale based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The pattern scale
   */

  function getScale(uint rand, int baseline) public pure returns (string memory) {
    uint scaleDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 7)] + baseline);

    bool isTexture = getIsTexture(rand, baseline);
    bool isAnimatedTexture = baseline < 70;

    uint scaleLength;
    uint scaleCount;
    string memory scales;

    if (isAnimatedTexture) {
      scaleLength = 4;
      scaleCount = 19;
      scales = ANIMATED_TEXTURE_NUMBERS;
    } else if (isTexture && !isAnimatedTexture) {
      scaleLength = 3;
      scaleCount = 31;
      scales = TEXTURE_SCALE_NUMBERS;
    } else {
      scaleLength = 4;
      scaleCount = 50;
      scales = PATTERNS_SCALE_NUMBERS;
    }

    uint[] memory scaleProbabilitiesArray = GridHelper.createEqualProbabilityArray(scaleCount);

    uint oneLess = scaleCount - 1;

    if (baseline > 185) {
      uint scaleValue = oneLess - (scaleDigits % 5);
      return string(GridHelper.slice(bytes(scales), scaleValue * scaleLength, scaleLength));
    }

    for (uint i = 0; i < oneLess; ++i) {
      if (scaleDigits < scaleProbabilitiesArray[i]) {
        return string(GridHelper.slice(bytes(scales), i * scaleLength, scaleLength));
      }
    }

    return string(GridHelper.slice(bytes(scales), oneLess * scaleLength, scaleLength));
  }

  /**
    * @dev Get the pattern opacity based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @param surfaceNumber The surface number 0 is left wall, 1 is right wall, 2 is floor
    * @return The pattern opacity as a string
   */

  function getOpacity(uint rand, int baseline, uint surfaceNumber) public pure returns (string memory) {
    uint opacityDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 8)] + baseline);

    bool[3] memory surfaceQuantity = getSurfaceQuantity(rand, baseline);

    if (!surfaceQuantity[surfaceNumber]) {
      return Strings.toString(0);
    }

    bool isTexture = getIsTexture(rand, baseline);

    if (isTexture) {
      // 100 -> 20
      return Strings.toString(100 - (opacityDigits * 80 / 255 + 20));
    } else {
      if (baseline > 185) {
        return Strings.toString(100);
      } else {
        // 25 -> 100
        return Strings.toString(opacityDigits * 75 / 255 + 25);
      }
    }
  }

  /**
    * @dev Get the pattern rotation based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The pattern rotation in degrees from 0 to 45
   */

  // Only used for textures
  function getRotate(uint rand, int baseline) public pure returns (uint) {
    uint rotateDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 9)] + baseline);

    // 0 -> 45
    return rotateDigits * 45 / 255;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Noise {
  // Normal distribution
  function getNoiseArrayZero() external pure returns (int256[256] memory) {
    int[256] memory noiseArray = [int(8), 16, 24, 32, 40, 40, 48, 48, 48, 56, 56, 64, 64, 64, 64, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 80, 80, 80, 80, 80, 80, 80, 80, 88, 88, 88, 88, 88, 88, 88, 88, 88, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 168, 168, 168, 168, 168, 168, 168, 168, 168, 168, 168, 176, 176, 176, 176, 176, 176, 176, 176, 176, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 192, 192, 192, 192, 200, 200, 200, 200, 200, 200, 200, 208, 208, 216, 224, 232, 240, 248];
    return noiseArray;
  }

  // Linear -64 -> 63
  function getNoiseArrayOne() external pure returns (int256[] memory) {
    return createLinearNoiseArray(128);
  }

  // Linear -16 -> 15
  function getNoiseArrayTwo() external pure returns (int256[] memory) {
    return createLinearNoiseArray(32);
  }

  // Linear -32 -> 31
  function getNoiseArrayThree() external pure returns (int256[] memory) {
    return createLinearNoiseArray(64);
  }

  // Create a linear noise array
  function createLinearNoiseArray(uint range) internal pure returns (int256[] memory) {
    int[] memory output = new int[](256);

    require(256 % range == 0, "range must be a factor of 256");

    require(range % 2 == 0, "range must be even");

    uint numOfCycles = 256 / range;

    int halfRange = int(range / 2);

    for (uint i = 0; i < numOfCycles; i++) {
      for (uint j = 0; j < range; ++j) {
        output[i * range + j] = int(j) - halfRange;
      }
    }

    return output;
  }
}