// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../styles/tubes/TubesCSS2.sol";

import "../styles/beast/BeastCSS1.sol";
import "../styles/beast/BeastCSS2.sol";
import "../styles/beast/BeastCSS3.sol";

import "../styles/conveyorBelt/ConveyorBeltCSS1.sol";
import "../styles/conveyorBelt/ConveyorBeltCSS2.sol";

contract Deployment12 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      TubesCSS2.getPart(),
      BeastCSS1.getPart(),
      BeastCSS2.getPart(),
      BeastCSS3.getPart(),
      ConveyorBeltCSS1.getPart(),
      ConveyorBeltCSS2.getPart()
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../../GridHelper.sol";
import "../../CommonSVG.sol";

library TubesCSS2 {
  string internal constant PART = "te(173.050007px,754.369995px)}24%{transform:translate(173.050007px,762.369995px)}}@keyframes tu-s-ellipse15_to__to{0%,33%,to{transform:translate(173.050007px,756.859985px)}19%{transform:translate(173.050007px,756.859985px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,744.859985px)}24%{transform:translate(173.050007px,752.859985px)}}@keyframes tu-s-ellipse16_to__to{0%,33%,to{transform:translate(173.050007px,749.349976px)}19%{transform:translate(173.050007px,749.349976px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,734.349976px)}24%{transform:translate(173.050007px,742.349976px)}}@keyframes tu-s-ellipse17_to__to{0%,33%,to{transform:translate(173.050007px,741.840027px)}19%{transform:translate(173.050007px,741.840027px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,722.840027px)}24%{transform:translate(173.050007px,730.840027px)}}@keyframes tu-s-ellipse18_to__to{0%,33%,to{transform:translate(173.050007px,734.330017px)}19%{transform:translate(173.050007px,734.330017px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,711.330017px)}24%{transform:translate(173.050007px,719.330017px)}}@keyframes tu-s-ellipse19_to__to{0%,33%,to{transform:translate(173.050007px,726.820007px)}19%{transform:translate(173.050007px,726.820007px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,697.820007px)}24%{transform:translate(173.050007px,705.820007px)}}@keyframes tu-s-ellipse20_to__to{0%,33%,to{transform:translate(173.050007px,719.309998px)}19%{transform:translate(173.050007px,719.309998px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.050007px,685.309998px)}24%{transform:translate(173.050007px,693.309998px)}}@keyframes tu-u-c-connector-c1-s1_to__to{0%,33%,to{transform:translate(173.040016px,711.039978px)}19%{transform:translate(173.040016px,711.039978px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.040016px,681.039978px)}24%{transform:translate(173.040016px,685.039978px)}}@keyframes tu-u-clippath2_to__to{0%,33%,to{transform:translate(173.040016px,711.039978px)}19%{transform:translate(173.040016px,711.039978px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}22%{transform:translate(173.040016px,681.039978px)}24%{transform:translate(173.040016px,685.039978px)}}@keyframes tu-u-lidmask-1-c1b-s1_to__to{0%,84%,to{transform:translate(123.299989px,513.473652px)}15%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}23%{transform:translate(123.299989px,502.473652px)}73%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes tu-u-lidmask-2-c1b-s1_to__to{0%,84%,to{transform:translate(123.299989px,530.473652px)}15%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}23%{transform:translate(123.299989px,542.473652px)}73%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes tu-u-lidmask-1-c1b-s12_to__to{0%,84%,to{transform:translate(123.299989px,513.473652px)}15%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}23%{transform:translate(123.299989px,502.473652px)}73%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes tu-u-lidmask-2-c1b-s12_to__to{0%,84%,to{transform:translate(123.299989px,530.473652px)}15%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}23%{transform:translate(123.299989px,542.473652px)}73%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes tu-u-c-gauge-b-ga_tr__tr{0%,27.5%,to{transform:translate(203.828552px,605.578796px) rotate(-129.847697deg)}12.5%{transform:translate(203.828552px,605.578796px) rotate(-129.847697deg);animation-timing-function:cubic-bezier(.455,.03,.515,.955)}15%{transform:translate(203.828552px,605.578796px) rotate(0deg);animation-timing-function:cubic-bezier(1,0,0,1)}17.5%{transform:translate(203.828552px,605.578796px) rotate(-27.522948deg)}25%{transform:translate(203.828552px,605.578796px) rotate(11.299863deg);animation-timing-function:cubic-bezier(.39,.575,.565,1)}}@keyframes tu-u-guage-m-oscillator_to__to{0%,20%,37%,49%,65%,80%,to{transform:translate(159.97081px,815.575012px)}34%,48%,63%,64%,79%{transform:translate(159.97081px,324.575012px)}}@keyframes tu-s-rect7_to__to{0%,87%,to{transform:translate(173.629701px,683.955798px)}22%{transform:translate(173.629701px,683.955798px);animation-timing-function:cubic-bezier(.42,0,1,1)}42%{transform:translate(173.629701px,563.955798px)}77%{transform:translate(173.629701px,563.955798px);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes tu-u-scanningline_to__to{0%,20%,30%,36%,60%{transform:translate(158.409996px,620.804932px)}15%,25%,33%,39%{transform:translate(158.409996px,620.804932px);animation-timing-function:cubic-bezier(.42,0,.58,1)}19.95%,29.95%,35.95%,59.95%{transform:translate(158.409996px,517.804932px)}61%{transform:translate(158.409996px,516.804932px);animation-timing-function:cubic-bezier(.42,0,.58,1)}85%,to{transform:translate(158.409996px,622.804932px)}}@keyframes tu-s-rect9_to__to{0%,90%,to{transform:translate(53.536959px,424.255383px)}35%{transform:translate(53.536959px,424.255383px);animation-timing-function:cubic-bezier(.42,0,.58,1)}55%{transform:translate(153.536959px,424.255383px)}80%{transform:translate(153.536959px,424.255383px);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes tu-u-line-a-5_to__to{0%,88.5%,to{transform:translate(427.01001px,667.529999px)}19.5%,32%,34%,46.5%,48%,60.5%,62%,74.5%,76%{transform:translate(427.01001px,667.529999px);animation-timing-function:cubic-bezier(0,0,.58,1)}27%,31.95%,41.5%,46.45%,55.5%,60.45%,69.5%,74.45%,83.5%,88.45%{transform:translate(536.01001px,604.529999px)}}@keyframes tu-s-g37_to__to{0%,41.5%,59%,81.5%,to{transform:translate(298.654999px,737.115021px)}58.95%,81.45%{transform:translate(662.654999px,524.115021px)}64%{transform:translate(295.654999px,736.115021px)}}@keyframes tu-u-bulb-idle_ts__ts{0%,32%,33.3%,34.5%,35.8%,37%,38.3%,to{transform:translate(612.950287px,622.822968px) scale(1,1)}32.35%,34.85%,37.35%{transform:translate(612.950287px,622.822968px) scale(1.6,1.6)}}@keyframes tu-u-bulb-idle_c_o{0%,39%{opacity:1}42%,to{opacity:0}}@keyframes tu-u-ring-an3_to__to{0%,20%{transform:translate(302.814987px,345.529999px)}47%,to{transform:translate(301.814987px,489.529999px)}}@keyframes tu-u-ring-an4_to__to{0%,20%{transform:translate(303.814987px,633.380005px)}24%{transform:translate(310.481654px,649.713338px)}30%{transform:translate(339.814987px,647.380005px)}34%{transform:translate(365.14832px,632.380005px);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:translate(409.922584px,603.072391px)}}@keyframes tu-u-ring-an4_tr__tr{0%,20%{transform:rotate(0deg)}24%{transform:rotate(-52deg)}30%{transform:rotate(-108deg)}34%{transform:rotate(-116.728151deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:rotate(-108.137865deg)}}@keyframes tu-u-ring-an32_to__to{0%,20%{transform:translate(300.814987px,489.459991px)}47%,to{transform:translate(302.814987px,633.459991px)}}@keyframes tu-u-ring-an2_to__to{0%,20%{transform:translate(235.77317px,303.014999px)}30%{transform:translate(280.77317px,281.014999px)}32%{transform:translate(287.27317px,281.514999px)}34%{transform:translate(294.77317px,286.014999px)}38%{transform:translate(302.27317px,299.014999px);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:translate(301.77317px,345.014999px)}}@keyframes tu-u-ring-an2_tr__tr{0%,20%,25%{transform:rotate(0deg)}33%{transform:rotate(55.159561deg)}38%{transform:rotate(104.63269deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:rotate(118.820612deg)}}@keyframes tu-u-ring-an_to__to{0%,20%{transform:translate(169.77317px,462.014999px)}24%{transform:translate(173.77317px,361.014999px)}33%{transform:translate(189.77317px,331.014999px)}34%{transform:translate(196.37317px,325.414999px);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:translate(235.77317px,303.014999px)}}@keyframes tu-u-ring-an_tr__tr{0%,20%,24%{transform:rotate(-57.988526deg)}34%{transform:rotate(-4.937661deg);animation-timing-function:cubic-bezier(.42,0,.58,1)}47%,to{transform:rotate(0deg)}}@keyframes tu-u-bbs_to__to{0%,24%{offset-distance:0}26.8%{offset-distance:18.776072%}29.85%{offset-distance:38.860758%}36.05%{offset-distance:80.400707%}39%,to{offset-distance:100%}}@keyframes tu-u-bbs2_to__to{0%,30.15%{offset-distance:0}32.95%{offset-distance:18.776072%}36%{offset-distance:38.860758%}42.2%{offset-distance:80.400707%}45.15%,to{offset-distance:100%}}@keyframes tu-u-bbs3_to__to{0%,37.15%{offset-distance:0}39.95%{offset-distance:18.776072%}43%{offset-distance:38.860758%}49.2%{offset-distance:80.400707%}52.15%,to{offset-distance:100%}}@keyframes tu-u-bbs4_to__to{0%,43.2%{offset-distance:0}46%{offset-distance:18.776072%}49.05%{offset-distance:38.860758%}55.25%{offset-distance:80.400707%}58.2%,to{offset-distance:100%}}@keyframes tu-u-fluid-c3b-s13_to__to{0%,75%,to{transform:translate(485.845016px,690.999985px)}40%{transform:translate(485.845016px,690.999985px);animation-timing-function:cubic-bezier(.314903,0,.659789,.399977)}60%{transform:translate(485.845016px,532.452075px);animation-timing-function:cubic-bezier(.42,0,.58,1)}70%{transform:translate(485.845016px,525.452075px);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes tu-u-fluidtop-c3l-s1_to__to{0%,75%,to{transform:translate(485.75499px,595.929993px)}40%{transform:translate(485.75499px,595.929993px);animation-timing-function:cubic-bezier(.42,0,1,1)}60%{transform:translate(485.75499px,440.003993px);animation-timing-function:cubic-bezier(.42,0,.58,1)}70%{transform:translate(485.75499px,433.003993px);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes tu-u-tube-c2-s1_tr__tr{0%,84%,to{transform:translate(526.396729px,405.039999px) rotate(0deg)}45%{transform:translate(526.396729px,405.039999px) rotate(0deg);animation-timing-function:cubic-bezier(.68,-.55,.265,1.55)}81.5%{transform:translate(526.396729px,405.039999px) rotate(66.701416deg)}}@keyframes tu-u-lidmask-1-c2b-s1_to__to{0%,90%,to{transform:translate(123.299989px,513.473652px)}59%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,.58,1)}67%{transform:translate(123.299989px,502.473652px)}83%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes tu-u-lidmask-2-c2b-s1_to__to{0%,90%,to{transform:translate(123.299989px,530.473652px)}59%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}67%{transform:translate(123.299989px,542.473652px)}83%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes tu-u-lidmask-1-c2b-s12_to__to{0%,90%,to{transform:translate(123.299989px,513.473652px)}59%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,.58,1)}67%{transform:translate(123.299989px,502.473652px)}83%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes tu-u-lidmask-2-c2b-s12_to__to{0%,90%,to{transform:translate(123.299989px,530.473652px)}59%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.445,.05,.55,.95)}67%{transform:translate(123.299989px,542.473652px)}83%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}}@keyframes tu-u-b-head_to__to{0%,34%,53%,to{transform:translate(554.423965px,346.723923px)}36%{transform:translate(542.423965px,339.723923px)}37%,51%{transform:translate(542.423965px,340.723923px)}}@keyframes tu-u-c-mineral-c-4_to__to{0%{offset-distance:0}61.75%{offset-distance:0;animation-timing-function:cubic-bezier(0,0,.58,1)}67.3%{offset-distance:36.985454%;animation-timing-function:cubic-bezier(.42,0,.58,1)}70.55%{offset-distance:58.68344%;animation-timing-function:cubic-bezier(.42,0,.58,1)}76.75%,to{offset-distance:100%}}@keyframes tu-u-c-mineral-c-4-2_to__to{0%,67.2%{offset-distance:0}72.75%{offset-distance:36.985454%;animation-timing-function:cubic-bezier(.42,0,.58,1)}76%{offset-distance:58.68344%;animation-timing-function:cubic-bezier(.42,0,.58,1)}82.2%,to{offset-distance:100%}}@keyframes tu-u-c-mineral-c-4-3_to__to{0%{offset-distance:0}73.2%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,.58,1)}78.75%{offset-distance:36.985454%;animation-timing-function:cubic-bezier(.42,0,.58,1)}82%{offset-distance:58.68344%;animation-timing-function:cubic-bezier(.42,0,.58,1)}88.2%,to{offset-distance:100%}}";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library BeastCSS1 {
  string internal constant PART = "@keyframes be-u-mg_to__to{0%,13%{offset-distance:0}23%,to{offset-distance:100%}}@keyframes be-u-mg2_to__to{0%,16%{offset-distance:0}26%,to{offset-distance:100%}}@keyframes be-u-mg3_to__to{0%,20%{offset-distance:0}30%,to{offset-distance:100%}}@keyframes be-u-mg4_to__to{0%,23%{offset-distance:0}33%,to{offset-distance:100%}}@keyframes be-u-mg5_to__to{0%,27%{offset-distance:0}37%,to{offset-distance:100%}}@keyframes be-u-mg6_to__to{0%,15%{offset-distance:0}25%,to{offset-distance:100%}}@keyframes be-u-mg7_to__to{0%,18%{offset-distance:0}28%,to{offset-distance:100%}}@keyframes be-u-mg8_to__to{0%,22%{offset-distance:0}32%,to{offset-distance:100%}}@keyframes be-u-mg9_to__to{0%,25%{offset-distance:0}35%,to{offset-distance:100%}}@keyframes be-u-mg10_to__to{0%,29%{offset-distance:0}39%,to{offset-distance:100%}}@keyframes be-u-bbs1_to__to{0%,25%{offset-distance:0}32%,to{offset-distance:100%}}@keyframes be-u-bbs12_to__to{0%,28%{offset-distance:0}35%,to{offset-distance:100%}}@keyframes be-u-bbs13_to__to{0%,31%{offset-distance:0}38%,to{offset-distance:100%}}@keyframes be-u-bbs14_to__to{0%,34%{offset-distance:0}41%,to{offset-distance:100%}}@keyframes be-u-bbs15_to__to{0%,38%{offset-distance:0}45%,to{offset-distance:100%}}@keyframes be-u-bbs16_to__to{0%,42%{offset-distance:0}49%,to{offset-distance:100%}}@keyframes be-u-bbs17_to__to{0%,46%{offset-distance:0}53%,to{offset-distance:100%}}@keyframes be-u-bbs18_to__to{0%,49%{offset-distance:0}56%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1_to__to{0%,53%{offset-distance:0}60%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-2_to__to{0%,56%{offset-distance:0}63%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-3_to__to{0%,59%{offset-distance:0}66%,to{offset-distance:100%}}@keyframes be-u-bbs19_to__to{0%,25%{offset-distance:0}32%,to{offset-distance:100%}}@keyframes be-u-bbs110_to__to{0%,28%{offset-distance:0}35%,to{offset-distance:100%}}@keyframes be-u-bbs111_to__to{0%,31%{offset-distance:0}38%,to{offset-distance:100%}}@keyframes be-u-bbs112_to__to{0%,34%{offset-distance:0}41%,to{offset-distance:100%}}@keyframes be-u-bbs113_to__to{0%,38%{offset-distance:0}45%,to{offset-distance:100%}}@keyframes be-u-bbs114_to__to{0%,42%{offset-distance:0}49%,to{offset-distance:100%}}@keyframes be-u-bbs115_to__to{0%,46%{offset-distance:0}53%,to{offset-distance:100%}}@keyframes be-u-bbs116_to__to{0%,49%{offset-distance:0}56%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs12_to__to{0%,53%{offset-distance:0}60%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-22_to__to{0%,56%{offset-distance:0}63%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-32_to__to{0%,59%{offset-distance:0}66%,to{offset-distance:100%}}@keyframes be-u-anim_to__to{0%,12.5%,22.5%,40%,50%,67.5%,77.5%,95%,to{transform:translate(621.372586px,641.698738px)}24%,51.5%,79%{transform:translate(621.372586px,694.698738px)}24.15%,51.65%,79.15%{transform:translate(621.372586px,723.698738px)}39.95%,67.45%,94.95%{transform:translate(621.372586px,726.698738px)}}@keyframes be-u-anim_ts__ts{0%,12.5%,39.95%,40%,67.45%,67.5%,94.95%,95%,to{transform:scale(0,0)}22.5%,24%,50%,51.5%,77.5%,79%{transform:scale(1,1)}24.15%,51.65%,79.15%{transform:scale(1,.1)}}@keyframes be-u-anim2_to__to{0%,12.5%{offset-distance:0}14%,17.4%{offset-distance:4.545455%}17.45%,17.5%{offset-distance:9.090909%}19%,22.4%{offset-distance:13.636364%}22.45%,22.5%{offset-distance:18.181818%}24%,27.4%{offset-distance:22.727273%}27.45%,27.5%{offset-distance:27.272727%}29%,32.4%{offset-distance:31.818182%}32.45%,32.5%{offset-distance:36.363636%}34%,37.4%{offset-distance:40.909091%}37.45%,37.5%{offset-distance:45.454545%}39%,42.4%{offset-distance:50%}42.45%,42.5%{offset-distance:54.545455%}44%,47.4%{offset-distance:59.090909%}47.45%,47.5%{offset-distance:63.636364%}49%,52.4%{offset-distance:68.181818%}52.45%,52.5%{offset-distance:72.727273%}54%,57.4%{offset-distance:77.272727%}57.45%,57.5%{offset-distance:81.818182%}59%,62.4%{offset-distance:86.363636%}62.45%,62.5%{offset-distance:90.909091%}64%,67.4%{offset-distance:95.454545%}67.45%,to{offset-distance:100%}}@keyframes be-u-anim2_ts__ts{0%,12.5%,14%,17.45%,17.5%,19%,22.45%,22.5%,24%,27.45%,27.5%,29%,32.45%,32.5%,34%,37.45%,37.5%,39%,42.45%,42.5%,44%,47.45%,47.5%,49%,52.45%,52.5%,54%,57.45%,57.5%,59%,62.45%,62.5%,64%,67.45%,to{transform:scale(1,1)}14.05%,19.05%,24.05%,29.05%,34.05%,39.05%,44.05%,49.05%,54.05%,59.05%,64.05%{transform:scale(1,.709633);animation-timing-function:cubic-bezier(0,0,.58,1)}17.4%,22.4%,27.4%,32.4%,37.4%,42.4%,47.4%,52.4%,57.4%,62.4%,67.4%{transform:scale(0,0)}}@keyframes be-u-el2-c1b-s1_to__to{0%,65.25%,to{transform:translate(469.56559px,412.879997px)}28%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-el1-c1b-s1_to__to{0%,65.25%,to{transform:translate(469.56559px,377.879997px)}28%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el1-c1b-s12_to__to{0%,65.25%,to{transform:translate(469.56559px,377.879997px)}28%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el2-c1b-s12_to__to{0%,65.25%,to{transform:translate(469.56559px,412.879997px)}28%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-face1-g0-s1_to__to{0%,28%{offset-distance:0}34.95%{offset-distance:46.19376%}35.95%{offset-distance:52.945981%}43%,to{offset-distance:100%}}@keyframes be-u-face1-g0-s1_tr__tr{0%,28%,32%{transform:rotate(0deg)}34%{transform:rotate(11deg)}35%{transform:rotate(21deg)}36%{transform:rotate(37deg)}39%,43%,to{transform:rotate(58deg)}}@keyframes be-u-face1-g0-s1_ts__ts{0%,27.95%,43.05%,to{transform:scale(0,0)}28%,43%{transform:scale(1,1)}}@keyframes be-u-face2-g0-s1_to__to{0%,44%{offset-distance:0}59%,to{offset-distance:100%}}@keyframes be-u-face2-g0-s1_tr__tr{0%,44%,48%{transform:rotate(0deg)}50%{transform:rotate(11deg)}51%{transform:rotate(21deg)}52%{transform:rotate(37deg)}55%,59%,to{transform:rotate(58deg)}}@keyframes be-u-face2-g0-s1_ts__ts{0%,43.95%,59.05%,to{transform:scale(0,0)}44%,59%{transform:scale(1,1)}}@keyframes be-u-ellipse-g0-s1_to__to{0%,28%{transform:translate(500.027161px,571.942809px)}32%{transform:translate(538.360494px,595.098365px)}34%{transform:translate(571.827161px,585.476143px)}35.55%{transform:translate(610.680494px,578.477254px)}37%{transform:translate(647.027161px,583.542809px)}42.95%{transform:translate(664.079078px,644.528584px)}43%{transform:translate(660.027161px,657.942809px)}43.95%{transform:translate(669.500886px,662.492809px)}44%{transform:translate(679.087904px,673.196294px)}44.95%{transform:translate(696.600236px,671.396009px)}48%{transform:translate(722.027161px,694.942809px)}50.95%{transform:translate(718.945753px,745.492167px)}51%{transform:translate(721.027161px,743.942809px)}52.95%{transform:translate(692.172669px,780.060188px)}54.95%{transform:translate(669.811136px,809.374859px)}55%{transform:translate(669.027161px,807.942809px)}59%,to{transform:translate(664.027161px,852.942809px)}}@keyframes be-u-ellipse-g0-s1_ts__ts{0%,27.95%,59.05%,to{transform:scale(0,0)}28%,59%{transform:scale(1.154299,1)}}@keyframes be-u-face1-g0-s12_to__to{0%,60%{offset-distance:0}66.95%{offset-distance:46.19376%}67.95%{offset-distance:52.945981%}75%,to{offset-distance:100%}}@keyframes be-u-face1-g0-s12_tr__tr{0%,60%,64%{transform:rotate(0deg)}66%{transform:rotate(11deg)}67%{transform:rotate(21deg)}68%{transform:rotate(37deg)}71%,75%,to{transform:rotate(58deg)}}@keyframes be-u-face1-g0-s12_ts__ts{0%,59.95%,75.05%,to{transform:scale(0,0)}60%,75%{transform:scale(1,1)}}@keyframes be-u-face2-g0-s12_to__to{0%,76%{offset-distance:0}91%,to{offset-distance:100%}}@keyframes be-u-face2-g0-s12_tr__tr{0%,76%,80%{transform:rotate(0deg)}82%{transform:rotate(11deg)}83%{transform:rotate(21deg)}84%{transform:rotate(37deg)}87%,91%,to{transform:rotate(58deg)}}@keyframes be-u-face2-g0-s12_ts__ts{0%,75.95%,91.05%,to{transform:scale(0,0)}76%,91%{transform:scale(1,1)}}@keyframes be-u-ellipse-g0-s12_to__to{0%,60%{transform:translate(500.027161px,571.942809px)}64%{transform:translate(538.360494px,595.098365px)}66%{transform:translate(571.827161px,585.476143px)}67.55%{transform:translate(610.680494px,578.477254px)}69%{transform:translate(647.027161px,583.542809px)}74.95%{transform:translate(664.079078px,644.528584px)}75%{transform:translate(660.027161px,657.942809px)}75.95%{transform:translate(669.500886px,662.492809px)}76%{transform:translate(679.087904px,673.196294px)}76.95%{transform:translate(696.600236px,671.396009px)}80%{transform:translate(722.027161px,694.942809px)}82.95%{transform:translate(718.945753px,745.492167px)}83%{transform:translate(721.027161px,743.942809px)}84.95%{transform:translate(692.172669px,780.060188px)}86.95%{transform:translate(669.811136px,809.374859px)}87%{transform:translate(669.027161px,807.942809px)}91%,to{transform:translate(664.027161px,852.942809px)}}@keyframes be-u-ellipse-g0-s12_ts__ts{0%,59.95%,91.05%,to{transform:scale(0,0)}60%,91%{transform:scale(1.154299,1)}}@keyframes be-u-face1-g0-s13_to__to{0%,45%{offset-distance:0}60%,to{offset-distance:100%}}@keyframes be-u-face1-g0-s13_tr__tr{0%,45%,49%{transform:rotate(0deg)}51%{transform:rotate(11deg)}52%{transform:rotate(21deg)}53%{transform:rotate(37deg)}56%,60%,to{transform:rotate(58deg)}}@keyframes be-u-face1-g0-s13_ts__ts{0%,44.95%,60.05%,to{transform:scale(0,0)}45%,60%{transform:scale(1,1)}}@keyframes be-u-face2-g0-s13_to__to{0%,61%{offset-distance:0}76%,to{offset-distance:100%}}@keyframes be-u-face2-g0-s13_tr__tr{0%,61%,65%{transform:rotate(0deg)}67%{transform:rotate(11deg)}68%{transform:rotate(21deg)}69%{transform:rotate(37deg)}72%,76%,to{transform:rotate(58deg)}}@keyframes be-u-face2-g0-s13_ts__ts{0%,60.95%,76.05%,to{transform:scale(0,0)}61%,76%{transform:scale(1,1)}}@keyframes be-u-ellipse-g0-s13_to__to{0%,45%{transform:translate(500.027161px,571.942809px)}49%{transform:translate(538.360494px,595.098365px)}51%{transform:translate(571.827161px,585.476143px)}52.55%{transform:translate(610.680494px,578.477254px)}54%{transform:translate(647.027161px,583.542809px)}60%{transform:translate(660.027161px,657.942809px)}61%{transform:translate(680.027161px,656.942809px)}65%{transform:translate(722.027161px,694.942809px)}68%{transform:translate(721.027161px,743.942809px)}72%{transform:translate(669.027161px,807.942809px)}76%,to{transform:translate(664.027161px,852.942809px)}}@keyframes be-u-ellipse-g0-s13_ts__ts{0%,44.95%,76.05%,to{transform:scale(0,0)}45%,76%{transform:scale(1.154299,1)}}@keyframes be-u-face1-g0-s14_to__to{0%,20%{offset-distance:0}35%,to{offset-distance:100%}}@keyframes be-u-face1-g0-s14_tr__tr{0%,20%,24%{transform:rotate(0deg)}26%{transform:rotate(11deg)}27%{transform:rotate(21deg)}28%{transform:rotate(37deg)}31%,35%,to{transform:rotate(58deg)}}@keyframes be-u-face1-g0-s14_ts__ts{0%,19.95%,35.05%,to{transform:scale(0,0)}20%,35%{transform:scale(1,1)}}@keyframes be-u-face2-g0-s14_to__to{0%,36%{offset-distance:0}51%,to{offset-distance:100%}}@keyframes be-u-face2-g0-s14_tr__tr{0%,36%,40%{transform:rotate(0deg)}42%{transform:rotate(11deg)}43%{transform:rotate(21deg)}44%{transform:rotate(37deg)}47%,51%,to{transform:rotate(58deg)}}@keyframes be-u-face2-g0-s14_ts__ts{0%,35.95%,51.05%,to{transform:scale(0,0)}36%,51%{transform:scale(1,1)}}@keyframes be-u-ellipse-g0-s14_to__to{0%,20%{transform:translate(500.027161px,571.942809px)}24%{transform:translate(538.360494px,595.098365px)}26%{transform:translate(571.827161px,585.476143px)}27.55%{transform:translate(610.680494px,578.477254px)}29%{transform:translate(647.027161px,583.542809px)}35%{transform:translate(660.027161px,657.942809px)}36%{transform:translate(680.027161px,656.942809px)}40%{transform:translate(722.027161px,694.942809px)}43%{transform:translate(721.027161px,743.942809px)}47%{transform:translate(669.027161px,807.942809px)}51%,to{transform:translate(664.027161px,852.942809px)}}@keyframes be-u-ellipse-g0-s14_ts__ts{0%,19.95%,51.05%,to{transform:scale(0,0)}20%,51%{transform:scale(1.154299,1)}}@keyframes be-u-lines_to__to{0%,26.5%,29%,31.5%,34%,36.5%,39%,41.5%,45.3%,47.8%,51.6%{transform:translate(935.269989px,526.210007px)}21%{transform:translate(935.269989px,526.210007px);animation-timing-function:cubic-bezier(.42,0,1,1)}25.2%,26.45%,27.7%,28.95%,30.2%,31.45%,32.7%,33.95%,35.2%,36.45%,37.7%,38.95%,40.2%,41.45%,42.7%,44%,45.25%,46.5%,47.75%,49%,50.3%,51.55%,52.8%,54.05%,58.5%,to{transform:translate(958.269989px,512.210007px)}25.25%,27.75%,30.25%,32.75%,35.25%,37.75%,40.25%,44.05%,46.55%,50.35%,52.85%{transform:translate(933.269989px,527.210007px)}42.75%,49.05%{transform:translate(933.269989px,527.210007px);animation-timing-function:cubic-bezier(0,0,.58,1)}54.1%{transform:translate(935.269989px,526.210007px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-lidmask-1-c1b-s1_to__to{0%,70.25%,to{transform:translate(123.299989px,513.473652px)}28.25%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}36.25%{transform:translate(123.299989px,502.473652px)}59.25%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-lidmask-2-c1b-s1_to__to{0%,70.25%,to{transform:translate(123.299989px,530.473652px)}28.25%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}36.25%{transform:translate(123.299989px,542.473652px)}59.25%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-lidmask-1-c1b-s12_to__to{0%,70.25%,to{transform:translate(123.299989px,513.473652px)}28.25%{transform:translate(123.299989px,513.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}36.25%{transform:translate(123.299989px,502.473652px)}59.25%{transform:translate(123.299989px,502.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-lidmask-2-c1b-s12_to__to{0%,70.25%,to{transform:translate(123.299989px,530.473652px)}28.25%{transform:translate(123.299989px,530.473652px);animation-timing-function:cubic-bezier(.42,0,1,1)}36.25%{transform:translate(123.299989px,542.473652px)}59.25%{transform:translate(123.299989px,542.473652px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-ellipse-yellow_c_o{0%,28%,63%,to{opacity:0}31%,60%{opacity:1}}@keyframes be-u-ellipse-bluel-c1-s1_c_o{0%,28%,63%,to{opacity:1}31%,60%{opacity:0}}@keyframes be-u-eye-lid1_to__to{0%,28%,63%,to{transform:translate(224.205292px,367.765588px)}31%,60%{transform:translate(224.205292px,347.765588px)}}@keyframes be-u-eye-lid2_to__to{0%,28%,63%,to{transform:translate(224.205292px,395.765588px)}31%,60%{transform:translate(224.205292px,415.765588px)}}@keyframes be-u-ellipse-yellow2_c_o{0%,28%,63%,to{opacity:0}31%,60%{opacity:1}}@keyframes be-u-ellipse-bluel-c1-s12_c_o{0%,28%,63%,to{opacity:1}31%,60%{opacity:0}}@keyframes be-u-eye-lid12_to__to{0%,28%,63%,to{transform:translate(224.205292px,367.765588px)}31%,60%{transform:translate(224.205292px,347.765588px)}}@keyframes be-u-eye-lid22_to__to{0%,28%,63%,to{transform:translate(224.205292px,395.765588px)}31%,60%{transform:translate(224.205292px,415.765588px)}}@keyframes be-u-lines2_to__to{0%,26.5%,29%,31.5%,34%,36.5%,39%,41.5%,45.3%,47.8%,51.6%{transform:translate(935.269989px,526.210007px)}21%{transform:translate(935.269989px,526.210007px);animation-timing-function:cubic-bezier(.42,0,1,1)}25.2%,26.45%,27.7%,28.95%,30.2%,31.45%,32.7%,33.95%,35.2%,36.45%,37.7%,38.95%,40.2%,41.45%,42.7%,44%,45.25%,46.5%,47.75%,49%,50.3%,51.55%,52.8%,54.05%,58.5%,to{transform:translate(958.269989px,512.210007px)}25.25%,27.75%,30.25%,32.75%,35.25%,37.75%,40.25%,44.05%,46.55%,50.35%,52.85%{transform:translate(933.269989px,527.210007px)}42.75%,49.05%{transform:translate(933.269989px,527.210007px);animation-timing-function:cubic-bezier(0,0,.58,1)}54.1%{transform:translate(935.269989px,526.210007px);animation-timing-function:cubic-bezier(0,0,.58,1)}}@keyframes be-u-pipe-circle_to__to{0%,15%{offset-distance:0}16.45%{offset-distance:7.254386%}18%{offset-distance:14.735332%}18.05%{offset-distance:28.421556%}19.5%{offset-distance:35.675942%}21.05%{offset-distance:43.156888%}21.1%{offset-distance:56.843112%}22.55%{offset-distance:64.097499%}24.1%{offset-distance:71.578444%}24.15%{offset-distance:85.264668%}25.6%{offset-distance:92.519055%}27.15%,to{offset-distance:100%}}@keyframes be-u-pipe-circle_tr__tr{0%,15%,18.05%,21.1%,24.15%{transform:rotate(0deg)}16.45%,19.5%,22.55%,25.6%{transform:rotate(1.719434deg)}17.25%,20.3%,23.35%,26.4%{transform:rotate(35.779675deg)}18%,21.05%,24.1%,27.15%,to{transform:rotate(59.258559deg)}}@keyframes be-u-pipe-circle_ts__ts{0%,15%,16.45%,18.05%,19.5%,21.1%,22.55%,24.15%,25.6%{transform:scale(1,1)}18%,21.05%,24.1%,27.15%,to{transform:scale(1,-1)}}@keyframes be-u-c-mineral-c_to__to{0%,15%{offset-distance:0}18%{offset-distance:9.098671%}21%{offset-distance:20.91148%}21.05%{offset-distance:39.54426%}24.05%{offset-distance:48.64293%}27.05%{offset-distance:60.45574%}27.1%{offset-distance:79.08852%}30.1%{offset-distance:88.18719%}33.1%,to{offset-distance:100%}}@keyframes be-u-c-mineral-c2_to__to{0%,9.85%{offset-distance:0}18%{offset-distance:54.326451%}25%,to{offset-distance:100%}}@keyframes be-u-c-mineral-c-22_to__to{0%,15%{offset-distance:0}23%{offset-distance:54.326451%}30%,to{offset-distance:100%}}@keyframes be-u-c-mineral-c-23_to__to{0%,5%{offset-distance:0}13%{offset-distance:54.326451%}20%,to{offset-distance:100%}}@keyframes be-s-path196_to__to{0%,40%,50%,60%,70%,80%{transform:tra";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library BeastCSS2 {
  string internal constant PART = "nslate(511.105334px,656.301752px)}49.95%,59.95%,69.95%,79.95%,89.95%,to{transform:translate(628.105334px,613.301752px)}}@keyframes be-u-g-hand_tr__tr{0%,40%,to{transform:translate(588.89px,668.663901px) rotate(-129.288885deg)}13%{transform:translate(588.89px,668.663901px) rotate(-129.288885deg);animation-timing-function:cubic-bezier(.68,-.55,.265,1.55)}28%{transform:translate(588.89px,668.663901px) rotate(-2.334911deg);animation-timing-function:cubic-bezier(.6,-.28,.735,.045)}}@keyframes be-s-rect2_to__to{0%,91%,to{transform:translate(173.629701px,683.955798px)}26%{transform:translate(173.629701px,683.955798px);animation-timing-function:cubic-bezier(.42,0,1,1)}46%{transform:translate(173.629701px,563.955798px)}81%{transform:translate(173.629701px,563.955798px);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes be-u-line-a-2_to__to{0%{offset-distance:0}45%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}54.95%{offset-distance:16.694858%}55%{offset-distance:33.347132%;animation-timing-function:cubic-bezier(.42,0,1,1)}64.95%{offset-distance:50.021292%}65%{offset-distance:66.673566%;animation-timing-function:cubic-bezier(.42,0,1,1)}74.95%{offset-distance:83.347726%}75%,to{offset-distance:100%}}@keyframes be-s-ellipse39_to__to{0%,27%{transform:translate(736.066618px,586.726397px)}27.5%{transform:translate(770.066618px,597.726397px)}28.25%,to{transform:translate(793.066618px,597.726397px)}}@keyframes be-s-ellipse39_tr__tr{0%,27%{transform:rotate(23.503186deg)}27.5%{transform:rotate(9.278868deg)}28.25%,to{transform:rotate(-12.67053deg)}}@keyframes be-s-ellipse39_ts__ts{0%,27%,27.5%{transform:scale(1,1)}28.25%,to{transform:scale(.00374,1)}}@keyframes be-u-c-mrsh-0_to__to{0%{offset-distance:0}22.5%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}24%{offset-distance:6.772026%}24.85%{offset-distance:21.088183%}25.5%{offset-distance:31.686175%}36%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-0_tr__tr{0%,22.5%{transform:rotate(24.570993deg)}24%{transform:rotate(24.702605deg)}25.5%,to{transform:rotate(26.670312deg)}}@keyframes be-u-c-mrsh-0_ts__ts{0%,22.5%,25.5%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}24%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-1_to__to{0%{offset-distance:0}24%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}25.5%{offset-distance:6.617267%}26.35%{offset-distance:20.60626%}27%{offset-distance:35.823519%}37.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-1_tr__tr{0%,24%{transform:rotate(24.570993deg)}25.5%{transform:rotate(24.702605deg)}27%{transform:rotate(26.670312deg)}38%,to{transform:rotate(18.615667deg)}}@keyframes be-u-c-mrsh-1_ts__ts{0%,24%,27%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}25.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-2_to__to{0%{offset-distance:0}26%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}27.5%{offset-distance:6.772026%}28.35%{offset-distance:21.088183%}29%{offset-distance:31.686175%}39.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-2_tr__tr{0%,26%{transform:rotate(24.570993deg)}27.5%{transform:rotate(24.702605deg)}29%,to{transform:rotate(38.963913deg)}}@keyframes be-u-c-mrsh-2_ts__ts{0%,26%,29%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}27.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-3_to__to{0%{offset-distance:0}27%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}28.5%{offset-distance:6.772026%}29.35%{offset-distance:21.088183%}30%{offset-distance:31.686175%}40.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-3_tr__tr{0%,27%{transform:rotate(24.570993deg)}28.5%{transform:rotate(24.702605deg)}30%,to{transform:rotate(18.352467deg)}}@keyframes be-u-c-mrsh-3_ts__ts{0%,27%,30%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}28.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-4_to__to{0%{offset-distance:0}29%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}30.5%{offset-distance:6.772026%}31.35%{offset-distance:21.088183%}32%{offset-distance:31.686175%}42.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-4_tr__tr{0%,29%{transform:rotate(24.570993deg)}30.5%{transform:rotate(24.702605deg)}32%,to{transform:rotate(26.670312deg)}}@keyframes be-u-c-mrsh-4_ts__ts{0%,29%,32%,to{transform:skewX(8deg) skewY(0deg) scale(1.411302,1)}30.5%{transform:skewX(8deg) skewY(0deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-02_to__to{0%{offset-distance:0}35.5%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}37%{offset-distance:6.772026%}37.85%{offset-distance:21.088183%}38.5%{offset-distance:31.686175%}49%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-02_tr__tr{0%,35.5%{transform:rotate(24.570993deg)}37%{transform:rotate(24.702605deg)}38.5%,to{transform:rotate(26.670312deg)}}@keyframes be-u-c-mrsh-02_ts__ts{0%,35.5%,38.5%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}37%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-12_to__to{0%{offset-distance:0}37%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}38.5%{offset-distance:6.617267%}39.35%{offset-distance:20.60626%}40%{offset-distance:35.823519%}50.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-12_tr__tr{0%,37%{transform:rotate(24.570993deg)}38.5%{transform:rotate(24.702605deg)}40%{transform:rotate(26.670312deg)}51%,to{transform:rotate(18.615667deg)}}@keyframes be-u-c-mrsh-12_ts__ts{0%,37%,40%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}38.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-22_to__to{0%{offset-distance:0}39%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}40.5%{offset-distance:6.772026%}41.35%{offset-distance:21.088183%}42%{offset-distance:31.686175%}52.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-22_tr__tr{0%,39%{transform:rotate(24.570993deg)}40.5%{transform:rotate(24.702605deg)}42%,to{transform:rotate(38.963913deg)}}@keyframes be-u-c-mrsh-22_ts__ts{0%,39%,42%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}40.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-32_to__to{0%{offset-distance:0}40%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}41.5%{offset-distance:6.772026%}42.35%{offset-distance:21.088183%}43%{offset-distance:31.686175%}53.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-32_tr__tr{0%,40%{transform:rotate(24.570993deg)}41.5%{transform:rotate(24.702605deg)}43%,to{transform:rotate(18.352467deg)}}@keyframes be-u-c-mrsh-32_ts__ts{0%,40%,43%,to{transform:skewX(12deg) skewY(-5deg) scale(1.411302,1)}41.5%{transform:skewX(12deg) skewY(-5deg) scale(1.753542,.923031)}}@keyframes be-u-c-mrsh-42_to__to{0%{offset-distance:0}42%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}43.5%{offset-distance:6.772026%}44.35%{offset-distance:21.088183%}45%{offset-distance:31.686175%}55.5%,to{offset-distance:100%}}@keyframes be-u-c-mrsh-42_tr__tr{0%,42%{transform:rotate(24.570993deg)}43.5%{transform:rotate(24.702605deg)}45%,to{transform:rotate(26.670312deg)}}@keyframes be-u-c-mrsh-42_ts__ts{0%,42%,45%,to{transform:skewX(8deg) skewY(0deg) scale(1.411302,1)}43.5%{transform:skewX(8deg) skewY(0deg) scale(1.753542,.923031)}}@keyframes be-u-c-candyfloss-b0_to__to{0%,27%{offset-distance:0}39%,to{offset-distance:100%}}@keyframes be-u-c-candyfloss-b0_tr__tr{0%,27%{transform:rotate(57.425226deg)}29%{transform:rotate(0deg)}39%,to{transform:rotate(-26.453691deg)}}@keyframes be-u-c-candyfloss-b1_to__to{0%,30%{offset-distance:0}42%,to{offset-distance:100%}}@keyframes be-u-c-candyfloss-b1_tr__tr{0%,30%{transform:rotate(57.425226deg)}32%{transform:rotate(0deg)}42%,to{transform:rotate(-26.453691deg)}}@keyframes be-u-c-candyfloss-b2_to__to{0%,33%{offset-distance:0}45%,to{offset-distance:100%}}@keyframes be-u-c-candyfloss-b2_tr__tr{0%,33%{transform:rotate(57.425226deg)}35%{transform:rotate(0deg)}45%,to{transform:rotate(-26.453691deg)}}@keyframes be-s-path223_to__to{0%,37.1%{transform:translate(751.905714px,591.328572px)}38%{transform:translate(769.905714px,604.328572px)}38.2%{transform:translate(770.232987px,604.092208px)}38.25%{transform:translate(772.814805px,605.283117px)}38.4%{transform:translate(772.46026px,604.855845px)}38.55%{transform:translate(774.105714px,606.428572px)}39%{transform:translate(774.905714px,606.328572px)}40%,to{transform:translate(779.905714px,607.328572px)}}@keyframes be-s-path223_ts__ts{0%,38%{transform:scale(1.0481,1)}39%{transform:scale(.363358,1)}40%,to{transform:scale(.004134,1)}}@keyframes be-s-path224_to__to{0%,37.55%{transform:translate(647.094292px,491.837495px)}38.25%{transform:translate(629.237149px,516.123209px)}38.9%{transform:translate(641.555516px,521.67423px)}40%{transform:translate(665.094292px,611.837495px)}40.05%,to{transform:translate(664.094292px,531.837495px)}}@keyframes be-s-path224_ts__ts{0%,37.5%{transform:scale(0,0)}37.55%,to{transform:scale(1,1)}}@keyframes be-u-sqf2_to__to{0%,40.05%{offset-distance:0}40.15%{offset-distance:.616956%}40.2%{offset-distance:1.174421%}40.3%{offset-distance:1.584588%}40.35%{offset-distance:1.687895%}40.5%{offset-distance:2.589386%}41%{offset-distance:5.457722%}41.35%{offset-distance:7.10768%}41.75%{offset-distance:9.203412%}42%{offset-distance:10.611533%}45%{offset-distance:29.244533%}48.5%{offset-distance:51.902279%}50%{offset-distance:59.824925%}52%{offset-distance:75.832447%}55%,to{offset-distance:100%}}@keyframes be-u-sqf2_tr__tr{0%,40.35%{transform:rotate(.248806deg)}40.5%,to{transform:rotate(0deg)}}@keyframes be-u-sqf2_tk__tk{0%,40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}42%,to{transform:skewX(0deg) skewY(0deg)}}@keyframes be-u-sqf2_ts__ts{0%,40%{transform:scale(0,0)}40.05%{transform:scale(-.043307,1)}40.2%{transform:scale(-.061476,1)}40.35%{transform:scale(-.130543,1)}40.5%{transform:scale(-.235,1)}41%{transform:scale(-.52,1)}42%,45%,to{transform:scale(-1,1)}}@keyframes be-u-frontb-g0-s1_to__to{0%,37.1%{offset-distance:0}38%{offset-distance:6.688492%}42%{offset-distance:12.039322%}47%{offset-distance:65.118205%}55%,to{offset-distance:100%}}@keyframes be-u-frontb-g0-s1_tk__tk{0%,37.1%,42%,to{transform:skewX(0deg) skewY(0deg)}38%{transform:skewX(0deg) skewY(1deg)}39%{transform:skewX(0deg) skewY(-20deg)}40%{transform:skewX(0deg) skewY(-83deg)}40.05%{transform:skewX(0deg) skewY(-87deg)}40.1%{transform:skewX(0deg) skewY(89deg)}40.2%{transform:skewX(0deg) skewY(81deg)}40.25%{transform:skewX(0deg) skewY(77deg)}40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-frontb-g0-s1_ts__ts{0%,39.95%{transform:scale(0,0)}40%{transform:scale(.05,1)}41%{transform:scale(-.52,1)}42%,to{transform:scale(-1,1)}}@keyframes be-u-fronta-g0-s1_to__to{0%,37.1%{offset-distance:0}38%{offset-distance:6.689497%}42%{offset-distance:12.041132%}55%,to{offset-distance:100%}}@keyframes be-u-fronta-g0-s1_tk__tk{0%,37.1%,42%,to{transform:skewX(0deg) skewY(0deg)}38%{transform:skewX(0deg) skewY(1deg)}39%{transform:skewX(0deg) skewY(-20deg)}40%{transform:skewX(0deg) skewY(-83deg)}40.05%{transform:skewX(0deg) skewY(-87deg)}40.1%{transform:skewX(0deg) skewY(89deg)}40.2%{transform:skewX(0deg) skewY(81deg)}40.25%{transform:skewX(0deg) skewY(77deg)}40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-fronta-g0-s1_ts__ts{0%,37.05%,40.2%,to{transform:scale(0,0)}37.1%{transform:scale(1,1)}38%{transform:scale(.996248,1)}40%{transform:scale(.05,1)}40.15%{transform:scale(-.0355,1)}}@keyframes be-u-backb-g0-s1_to__to{0%,43.6%{offset-distance:0}44.5%{offset-distance:6.688492%}48.5%{offset-distance:12.039322%}53.5%{offset-distance:65.118205%}61.5%,to{offset-distance:100%}}@keyframes be-u-backb-g0-s1_tk__tk{0%,43.6%,48.5%,to{transform:skewX(0deg) skewY(0deg)}44.5%{transform:skewX(0deg) skewY(1deg)}45.5%{transform:skewX(0deg) skewY(-20deg)}46.5%{transform:skewX(0deg) skewY(-83deg)}46.55%{transform:skewX(0deg) skewY(-87deg)}46.6%{transform:skewX(0deg) skewY(89deg)}46.7%{transform:skewX(0deg) skewY(81deg)}46.75%{transform:skewX(0deg) skewY(77deg)}47%{transform:skewX(0deg) skewY(58deg)}47.5%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-backb-g0-s1_ts__ts{0%,46.45%{transform:scale(0,0)}46.5%{transform:scale(.05,1)}47.5%{transform:scale(-.52,1)}48.5%,to{transform:scale(-1,1)}}@keyframes be-u-backa-g0-s1_to__to{0%,43.6%{offset-distance:0}44.5%{offset-distance:6.689497%}48.5%{offset-distance:12.041132%}61.5%,to{offset-distance:100%}}@keyframes be-u-backa-g0-s1_tk__tk{0%,43.6%,48.5%,to{transform:skewX(0deg) skewY(0deg)}44.5%{transform:skewX(0deg) skewY(1deg)}45.5%{transform:skewX(0deg) skewY(-20deg)}46.5%{transform:skewX(0deg) skewY(-83deg)}46.55%{transform:skewX(0deg) skewY(-87deg)}46.6%{transform:skewX(0deg) skewY(89deg)}46.7%{transform:skewX(0deg) skewY(81deg)}46.75%{transform:skewX(0deg) skewY(77deg)}47%{transform:skewX(0deg) skewY(58deg)}47.5%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-backa-g0-s1_ts__ts{0%,43.55%,46.7%,to{transform:scale(0,0)}43.6%{transform:scale(1,1)}44.5%{transform:scale(.996248,1)}46.5%{transform:scale(.05,1)}46.65%{transform:scale(-.0355,1)}}@keyframes be-u-eight_to__to{0%,46.6%{transform:translate(856.614527px,556.512772px)}47%{transform:translate(865.825053px,554.407509px)}47.4%{transform:translate(874.768913px,552.302246px)}48.1%{transform:translate(888.034304px,548.618035px)}48.5%{transform:translate(895.614527px,546.512772px)}53.5%,to{transform:translate(1044.614527px,450.512772px)}}@keyframes be-u-eight_ts__ts{0%,45.8%{transform:scale(0,0)}45.85%,to{transform:scale(1,1)}}@keyframes be-u-seventh_to__to{0%,48.5%{transform:translate(898.015506px,534.377499px)}53.5%,to{transform:translate(1050.015506px,449.377499px)}}@keyframes be-u-seventh_ts__ts{0%,48.5%{transform:scale(0,0)}48.55%,53.5%,to{transform:scale(1,1)}}@keyframes be-u-six_to__to{0%,43.65%{transform:translate(869.438082px,566.1433px)}45.4%{transform:translate(921.438082px,535.1433px)}46.6%{transform:translate(957.315633px,515.449422px)}47.85%{transform:translate(982.438082px,504.1433px)}50.05%{transform:translate(1008.284236px,486.297146px)}52.45%,to{transform:translate(1078.48004px,436.828615px)}}@keyframes be-u-six_ts__ts{0%,43.6%{transform:scale(0,0)}43.65%,47.85%,50%{transform:scale(1,1)}50.05%,to{transform:scale(.986415,1)}}@keyframes be-u-fith_to__to{0%,43.6%{transform:translate(722.053569px,575.739999px)}44.5%{transform:translate(740.053569px,587.739999px)}45.85%{transform:translate(765.767855px,601.739999px)}46.6%,to{transform:translate(780.053569px,606.739999px)}}@keyframes be-u-fith_ts__ts{0%,43.55%,46.65%,to{transform:scale(0,0)}43.6%{transform:scale(1,1)}44.5%{transform:scale(.986654,1)}44.9%{transform:scale(.665586,1)}45.25%{transform:scale(.492696,1)}45.4%{transform:scale(.398707,1)}45.7%{transform:scale(.274707,1)}45.85%{transform:scale(.219841,1)}46.25%{transform:scale(.101283,1)}46.35%{transform:scale(.073115,1)}46.6%{transform:scale(.009692,1)}}@keyframes be-u-fourth_to__to{0%,40.1%{transform:translate(781.036835px,606.679999px)}40.5%{transform:translate(791.036835px,604.679999px)}42%{transform:translate(820.036835px,589.679999px)}43.55%,to{transform:translate(865.036835px,564.679999px)}}@keyframes be-u-fourth_ts__ts{0%,40.05%,43.6%,to{transform:scale(0,0)}40.1%{transform:scale(.053328,1)}40.5%{transform:scale(.157951,1)}41%{transform:scale(.351305,1)}42%{transform:scale(.957892,1)}43.55%{transform:scale(1,1)}}@keyframes be-u-firstmask_to__to{0%,37.1%{transform:translate(753.62px,559.33px)}38%{transform:translate(772.72px,570.53px)}40.1%,43.6%,to{transform:translate(780.62px,573.33px)}}@keyframes be-u-firstmask_tr__tr{0%,37.1%{transform:rotate(0deg)}37.15%{transform:rotate(.69806deg)}38%{transform:rotate(1.167512deg)}39.2%{transform:rotate(-32.772874deg)}40.1%{transform:rotate(-58.819948deg)}43.6%,to{transform:rotate(-59.1682deg)}}@keyframes be-u-firstmask_ts__ts{0%,37.1%,43.55%{transform:scale(1,1)}43.6%,to{transform:scale(0,0)}}@keyframes be-u-ninth_to__to{0%,46.6%{transform:translate(802.483531px,581.72625px)}48.1%{transform:translate(808.483531px,581.72625px)}48.15%{transform:translate(809.483531px,581.72625px)}48.5%,to{transform:translate(810.483531px,581.72625px)}}@keyframes be-u-ninth_ts__ts{0%,46.55%,48.55%,to{transform:scale(0,0)}46.6%,48.5%{transform:scale(1,1)}}@keyframes be-u-secondmask_to__to{0%,37.1%{transform:translate(647.789289px,594.717494px)}38%{transform:translate(666.489289px,601.017494px)}38.6%{transform:translate(677.503575px,605.217494px)}39.2%{transform:translate(688.51786px,609.417494px)}39.65%{transform:translate(697.653575px,612.567494px)}40.1%,43.6%,to{transform:translate(706.789289px,615.717494px)}}@keyframes be-u-secondmask_tr__tr{0%,37.1%,43.6%,to{transform:rotate(0deg)}}@keyframes be-u-secondmask_ts__ts{0%,37.1%,43.55%{transform:scale(1,1)}43.6%,to{transform:scale(0,0)}}@keyframes be-u-thirdmask_to__to{0%,40.1%{transform:translate(781.004342px,573.038862px)}42%{transform:translate(788.004342px,571.038862px)}43.6%,to{transform:translate(836.004342px,544.038862px)}}@keyframes be-u-thirdmask_tr__tr{0%,40.1%{transform:rotate(59.588418deg)}42%{transform:rotate(27.895357deg)}43.6%,to{transform:rotate(27.914596deg)}}@keyframes be-u-thirdmask_ts__ts{0%,40.05%,43.6%,to{transform:scale(0,0)}40.1%,43.55%{transform:scale(1,1)}}@keyframes be-u-frontbackrects1_ts__ts{0%,46.55%{transform:translate(798.88498px,588.491272px) scale(0,0)}46.6%,to{transform:translate(798.88498px,588.491272px) scale(1,1)}}@keyframes be-s-path232_to__to{0%,37.1%{transform:translate(751.905714px,591.328572px)}38%{transform:translate(769.905714px,604.328572px)}38.2%{transform:translate(770.232987px,604.092208px)}38.25%{transform:t";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library BeastCSS3 {
  string internal constant PART = "ranslate(772.814805px,605.283117px)}38.4%{transform:translate(772.46026px,604.855845px)}38.55%{transform:translate(774.105714px,606.428572px)}39%{transform:translate(774.905714px,606.328572px)}40%,to{transform:translate(779.905714px,607.328572px)}}@keyframes be-s-path232_ts__ts{0%,38%{transform:scale(1.0481,1)}39%{transform:scale(.363358,1)}40%,to{transform:scale(.004134,1)}}@keyframes be-s-path233_to__to{0%,37.55%{transform:translate(647.094292px,491.837495px)}38.25%{transform:translate(629.237149px,516.123209px)}38.9%{transform:translate(641.555516px,521.67423px)}40%{transform:translate(665.094292px,611.837495px)}40.05%,to{transform:translate(664.094292px,531.837495px)}}@keyframes be-s-path233_ts__ts{0%,37.5%{transform:scale(0,0)}37.55%,to{transform:scale(1,1)}}@keyframes be-u-sqf22_to__to{0%,40.05%{offset-distance:0}40.15%{offset-distance:.616956%}40.2%{offset-distance:1.174421%}40.3%{offset-distance:1.584588%}40.35%{offset-distance:1.687895%}40.5%{offset-distance:2.589386%}41%{offset-distance:5.457722%}41.35%{offset-distance:7.10768%}41.75%{offset-distance:9.203412%}42%{offset-distance:10.611533%}45%{offset-distance:29.244533%}48.5%{offset-distance:51.902279%}50%{offset-distance:59.824925%}52%{offset-distance:75.832447%}55%,to{offset-distance:100%}}@keyframes be-u-sqf22_tr__tr{0%,40.35%{transform:rotate(.248806deg)}40.5%,to{transform:rotate(0deg)}}@keyframes be-u-sqf22_tk__tk{0%,40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}42%,to{transform:skewX(0deg) skewY(0deg)}}@keyframes be-u-sqf22_ts__ts{0%,40%{transform:scale(0,0)}40.05%{transform:scale(-.043307,1)}40.2%{transform:scale(-.061476,1)}40.35%{transform:scale(-.130543,1)}40.5%{transform:scale(-.235,1)}41%{transform:scale(-.52,1)}42%,45%,to{transform:scale(-1,1)}}@keyframes be-u-frontb-g0-s12_to__to{0%,37.1%{offset-distance:0}38%{offset-distance:6.688492%}42%{offset-distance:12.039322%}47%{offset-distance:65.118205%}55%,to{offset-distance:100%}}@keyframes be-u-frontb-g0-s12_tk__tk{0%,37.1%,42%,to{transform:skewX(0deg) skewY(0deg)}38%{transform:skewX(0deg) skewY(1deg)}39%{transform:skewX(0deg) skewY(-20deg)}40%{transform:skewX(0deg) skewY(-83deg)}40.05%{transform:skewX(0deg) skewY(-87deg)}40.1%{transform:skewX(0deg) skewY(89deg)}40.2%{transform:skewX(0deg) skewY(81deg)}40.25%{transform:skewX(0deg) skewY(77deg)}40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-frontb-g0-s12_ts__ts{0%,39.95%,46.6%,to{transform:scale(0,0)}40%{transform:scale(.05,1)}41%{transform:scale(-.52,1)}42%,46.55%{transform:scale(-1,1)}}@keyframes be-u-fronta-g0-s12_to__to{0%,37.1%{offset-distance:0}38%{offset-distance:6.689497%}42%{offset-distance:12.041132%}55%,to{offset-distance:100%}}@keyframes be-u-fronta-g0-s12_tk__tk{0%,37.1%,42%,to{transform:skewX(0deg) skewY(0deg)}38%{transform:skewX(0deg) skewY(1deg)}39%{transform:skewX(0deg) skewY(-20deg)}40%{transform:skewX(0deg) skewY(-83deg)}40.05%{transform:skewX(0deg) skewY(-87deg)}40.1%{transform:skewX(0deg) skewY(89deg)}40.2%{transform:skewX(0deg) skewY(81deg)}40.25%{transform:skewX(0deg) skewY(77deg)}40.5%{transform:skewX(0deg) skewY(58deg)}41%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-fronta-g0-s12_ts__ts{0%,37.05%,40.2%,to{transform:scale(0,0)}37.1%{transform:scale(1,1)}38%{transform:scale(.996248,1)}40%{transform:scale(.05,1)}40.15%{transform:scale(-.0355,1)}}@keyframes be-u-backb-g0-s12_to__to{0%,43.6%{offset-distance:0}44.5%{offset-distance:6.688492%}48.5%{offset-distance:12.039322%}53.5%{offset-distance:65.118205%}61.5%,to{offset-distance:100%}}@keyframes be-u-backb-g0-s12_tk__tk{0%,43.6%,48.5%,to{transform:skewX(0deg) skewY(0deg)}44.5%{transform:skewX(0deg) skewY(1deg)}45.5%{transform:skewX(0deg) skewY(-20deg)}46.5%{transform:skewX(0deg) skewY(-83deg)}46.55%{transform:skewX(0deg) skewY(-87deg)}46.6%{transform:skewX(0deg) skewY(89deg)}46.7%{transform:skewX(0deg) skewY(81deg)}46.75%{transform:skewX(0deg) skewY(77deg)}47%{transform:skewX(0deg) skewY(58deg)}47.5%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-backb-g0-s12_ts__ts{0%,46.45%{transform:scale(0,0)}46.5%{transform:scale(.05,1)}47.5%{transform:scale(-.52,1)}48.5%,to{transform:scale(-1,1)}}@keyframes be-u-backa-g0-s12_to__to{0%,43.6%{offset-distance:0}44.5%{offset-distance:6.689497%}48.5%{offset-distance:12.041132%}61.5%,to{offset-distance:100%}}@keyframes be-u-backa-g0-s12_tk__tk{0%,43.6%,48.5%,to{transform:skewX(0deg) skewY(0deg)}44.5%{transform:skewX(0deg) skewY(1deg)}45.5%{transform:skewX(0deg) skewY(-20deg)}46.5%{transform:skewX(0deg) skewY(-83deg)}46.55%{transform:skewX(0deg) skewY(-87deg)}46.6%{transform:skewX(0deg) skewY(89deg)}46.7%{transform:skewX(0deg) skewY(81deg)}46.75%{transform:skewX(0deg) skewY(77deg)}47%{transform:skewX(0deg) skewY(58deg)}47.5%{transform:skewX(0deg) skewY(24deg)}}@keyframes be-u-backa-g0-s12_ts__ts{0%,43.55%,46.7%,to{transform:scale(0,0)}43.6%{transform:scale(1,1)}44.5%{transform:scale(.996248,1)}46.5%{transform:scale(.05,1)}46.65%{transform:scale(-.0355,1)}}@keyframes be-u-floob-a-clips-anims_ts__ts{0%,26.45%,37.05%,39.95%{transform:translate(0,0) scale(0,0)}26.5%,37%,40%,to{transform:translate(0,0) scale(1,1)}}@keyframes be-u-c-floob_tube2_ts__ts{0%,39.95%{transform:translate(795.55777px,581.746307px) scale(0,0)}40%,to{transform:translate(795.55777px,581.746307px) scale(1,1)}}@keyframes be-u-floob-shadow_ts__ts{0%,41.7%,44.8%,to{transform:translate(761.329987px,621.764435px) scale(0,0)}41.75%,42%,44.5%,44.75%{transform:translate(761.329987px,621.764435px) scale(1,1)}}@keyframes be-u-e-start-ending-g0-s1_to__to{0%,43.9%{transform:translate(737.822993px,583.668347px)}45%{transform:translate(768.622993px,595.935014px)}45.4%{transform:translate(779.822993px,597.668347px)}45.85%{transform:translate(799.822993px,591.668347px)}47.5%{transform:translate(860.020795px,557.217798px)}50.4%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-start-ending-g0-s1_tr__tr{0%,43.9%{transform:rotate(29.654433deg)}45.4%{transform:rotate(1.738143deg)}45.85%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-start-ending-g0-s1_ts__ts{0%,43.9%,45%{transform:scale(.962069,1.098314)}45.4%{transform:scale(0,1.098314)}45.85%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-u-e-end-g0-s1_to__to{0%,40%{transform:translate(737.822993px,583.668347px)}41.1%{transform:translate(768.622993px,595.935014px)}41.5%{transform:translate(779.822993px,597.668347px)}41.95%{transform:translate(799.822993px,591.668347px)}46.5%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-end-g0-s1_tr__tr{0%,40%{transform:rotate(29.654433deg)}41.5%{transform:rotate(1.738143deg)}41.95%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-end-g0-s1_ts__ts{0%,40%,41.1%{transform:scale(.962069,1.098314)}41.5%{transform:scale(0,1.098314)}41.95%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-s-path237_to__to{0%,40%{transform:translate(792.730005px,568.134098px)}42%{transform:translate(811.730005px,514.134094px)}44%{transform:translate(870.730005px,460.134089px)}44.05%{transform:translate(871.030005px,464.784089px)}44.5%{transform:translate(876.730005px,446.791984px)}45%{transform:translate(876.730005px,433.134089px)}45.5%{transform:translate(841.730005px,400.134089px)}46%{transform:translate(806.730005px,393.134089px)}50%,to{transform:translate(946.730005px,293.134089px)}}@keyframes be-s-path237_tr__tr{0%,39.95%{transform:rotate(95.142753deg)}40%{transform:rotate(65.413687deg)}42%{transform:rotate(15.187061deg)}44%{transform:rotate(7.870587deg)}44.05%{transform:rotate(8.619362deg)}44.5%{transform:rotate(2.612279deg)}45%{transform:rotate(-4.046775deg)}45.3%{transform:rotate(-12.172571deg)}45.5%{transform:rotate(-19.574548deg)}46%,to{transform:rotate(-37.017165deg)}}@keyframes be-u-e-start-g0-s1_to__to{0%,40%{transform:translate(737.822993px,583.668347px)}41.1%{transform:translate(768.622993px,595.935014px)}41.5%{transform:translate(779.822993px,597.668347px)}41.95%{transform:translate(799.822993px,591.668347px)}43.6%{transform:translate(860.020795px,557.217798px)}46.5%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-start-g0-s1_tr__tr{0%,40%{transform:rotate(29.654433deg)}41.5%{transform:rotate(1.738143deg)}41.95%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-start-g0-s1_ts__ts{0%,39.95%,41.9%,to{transform:scale(0,0)}40%,41.1%{transform:scale(.962069,1.098314)}41.85%{transform:scale(0,1.098314)}}@keyframes be-s-g148_to__to{0%,40%{transform:translate(825.36145px,577.052978px)}43.9%{transform:translate(737.822993px,583.668347px)}45%{transform:translate(768.622993px,595.935014px)}45.4%{transform:translate(779.822993px,597.668347px)}45.85%{transform:translate(799.822993px,591.668347px)}47.5%{transform:translate(860.020795px,557.217798px)}50.4%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-s-g148_tr__tr{0%,43.9%{transform:rotate(29.654433deg)}45.4%{transform:rotate(1.738143deg)}45.85%,to{transform:rotate(-23.815863deg)}}@keyframes be-s-g148_ts__ts{0%,45.35%{transform:scale(0,0)}45.4%{transform:scale(0,1.098314)}45.85%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-u-floob-shadow2_ts__ts{0%,28.2%,31.3%,to{transform:translate(761.329987px,621.764435px) scale(0,0)}28.25%,28.5%,31%,31.25%{transform:translate(761.329987px,621.764435px) scale(1,1)}}@keyframes be-u-e-start-ending-g0-s12_to__to{0%,30.4%{transform:translate(737.822993px,583.668347px)}31.5%{transform:translate(768.622993px,595.935014px)}31.9%{transform:translate(779.822993px,597.668347px)}32.35%{transform:translate(799.822993px,591.668347px)}34%{transform:translate(860.020795px,557.217798px)}36.9%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-start-ending-g0-s12_tr__tr{0%,30.4%{transform:rotate(29.654433deg)}31.9%{transform:rotate(1.738143deg)}32.35%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-start-ending-g0-s12_ts__ts{0%,30.4%,31.5%{transform:scale(.962069,1.098314)}31.9%{transform:scale(0,1.098314)}32.35%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-u-e-end-g0-s12_to__to{0%,26.5%{transform:translate(737.822993px,583.668347px)}27.6%{transform:translate(768.622993px,595.935014px)}28%{transform:translate(779.822993px,597.668347px)}28.45%{transform:translate(799.822993px,591.668347px)}33%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-end-g0-s12_tr__tr{0%,26.5%{transform:rotate(29.654433deg)}28%{transform:rotate(1.738143deg)}28.45%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-end-g0-s12_ts__ts{0%,26.5%,27.6%{transform:scale(.962069,1.098314)}28%{transform:scale(0,1.098314)}28.45%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-s-path239_to__to{0%,26.5%{transform:translate(792.730005px,568.134098px)}28.5%{transform:translate(811.730005px,514.134094px)}30.5%{transform:translate(870.730005px,460.134089px)}30.55%{transform:translate(871.030005px,464.784089px)}31%{transform:translate(876.730005px,446.791984px)}31.5%{transform:translate(876.730005px,433.134089px)}32%{transform:translate(841.730005px,400.134089px)}32.5%{transform:translate(806.730005px,393.134089px)}36.5%,to{transform:translate(946.730005px,293.134089px)}}@keyframes be-s-path239_tr__tr{0%,26.45%{transform:rotate(95.142753deg)}26.5%{transform:rotate(65.413687deg)}28.5%{transform:rotate(15.187061deg)}30.5%{transform:rotate(7.870587deg)}30.55%{transform:rotate(8.619362deg)}31%{transform:rotate(2.612279deg)}31.5%{transform:rotate(-4.046775deg)}31.8%{transform:rotate(-12.172571deg)}32%{transform:rotate(-19.574548deg)}32.5%,to{transform:rotate(-37.017165deg)}}@keyframes be-u-e-start-g0-s12_to__to{0%,26.5%{transform:translate(737.822993px,583.668347px)}27.6%{transform:translate(768.622993px,595.935014px)}28%{transform:translate(779.822993px,597.668347px)}28.45%{transform:translate(799.822993px,591.668347px)}30.1%{transform:translate(860.020795px,557.217798px)}33%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-u-e-start-g0-s12_tr__tr{0%,26.5%{transform:rotate(29.654433deg)}28%{transform:rotate(1.738143deg)}28.45%,to{transform:rotate(-23.815863deg)}}@keyframes be-u-e-start-g0-s12_ts__ts{0%,26.45%,28.4%,to{transform:scale(0,0)}26.5%,27.6%{transform:scale(.962069,1.098314)}28.35%{transform:scale(0,1.098314)}}@keyframes be-s-g149_to__to{0%,26.5%{transform:translate(825.36145px,577.052978px)}30.4%{transform:translate(737.822993px,583.668347px)}31.5%{transform:translate(768.622993px,595.935014px)}31.9%{transform:translate(779.822993px,597.668347px)}32.35%{transform:translate(799.822993px,591.668347px)}34%{transform:translate(860.020795px,557.217798px)}36.9%,to{transform:translate(965.822993px,496.668347px)}}@keyframes be-s-g149_tr__tr{0%,30.4%{transform:rotate(29.654433deg)}31.9%{transform:rotate(1.738143deg)}32.35%,to{transform:rotate(-23.815863deg)}}@keyframes be-s-g149_ts__ts{0%,31.85%{transform:scale(0,0)}31.9%{transform:scale(0,1.098314)}32.35%,to{transform:scale(-1.096188,1.098314)}}@keyframes be-u-el2-c1b-s13_to__to{0%,65.25%,to{transform:translate(469.56559px,412.879997px)}28%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-el1-c1b-s13_to__to{0%,65.25%,to{transform:translate(469.56559px,377.879997px)}28%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el1-c1b-s14_to__to{0%,65.25%,to{transform:translate(469.56559px,377.879997px)}28%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el2-c1b-s14_to__to{0%,65.25%,to{transform:translate(469.56559px,412.879997px)}28%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}33%,59.25%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-bbs117_to__to{0%,25%{offset-distance:0}32%,to{offset-distance:100%}}@keyframes be-u-bbs118_to__to{0%,28%{offset-distance:0}35%,to{offset-distance:100%}}@keyframes be-u-bbs119_to__to{0%,31%{offset-distance:0}38%,to{offset-distance:100%}}@keyframes be-u-bbs120_to__to{0%,34%{offset-distance:0}41%,to{offset-distance:100%}}@keyframes be-u-bbs121_to__to{0%,38%{offset-distance:0}45%,to{offset-distance:100%}}@keyframes be-u-bbs122_to__to{0%,42%{offset-distance:0}49%,to{offset-distance:100%}}@keyframes be-u-bbs123_to__to{0%,46%{offset-distance:0}53%,to{offset-distance:100%}}@keyframes be-u-bbs124_to__to{0%,49%{offset-distance:0}56%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs13_to__to{0%,53%{offset-distance:0}60%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-23_to__to{0%,56%{offset-distance:0}63%,to{offset-distance:100%}}@keyframes be-u-copy-of-bbs1-33_to__to{0%,59%{offset-distance:0}66%,to{offset-distance:100%}}@keyframes be-u-group-onoff_ts__ts{0%,25%,26.5%,27.5%,29%,31%,32.5%,33.5%,35%,to{transform:translate(552.225006px,393.769989px) scale(1,1)}25.5%,28%,31.5%,34%{transform:translate(552.225006px,393.769989px) scale(1.1,1.1)}}@keyframes be-u-bulb-on_ts__ts{0%,34.95%,69.05%,to{transform:translate(552.225006px,393.769989px) scale(0,0)}35%,69%{transform:translate(552.225006px,393.769989px) scale(1,1)}}@keyframes be-u-group-onoff2_ts__ts{0%,25%,26.5%,27.5%,29%,31%,32.5%,33.5%,35%,to{transform:translate(552.225006px,393.769989px) scale(1,1)}25.5%,28%,31.5%,34%{transform:translate(552.225006px,393.769989px) scale(1.1,1.1)}}@keyframes be-u-bulb-on2_ts__ts{0%,34.95%,69.05%,to{transform:translate(552.225006px,393.769989px) scale(0,0)}35%,69%{transform:translate(552.225006px,393.769989px) scale(1,1)}}@keyframes be-u-el1-c1b-s15_to__to{0%,90.5%,to{transform:translate(469.56559px,377.879997px)}37.75%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}42.75%,84.5%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el2-c1b-s15_to__to{0%,90.5%,to{transform:translate(469.56559px,412.879997px)}37.75%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}42.75%,84.5%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-el1-c1b-s16_to__to{0%,90.5%,to{transform:translate(469.56559px,377.879997px)}37.75%{transform:translate(469.56559px,377.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}42.75%,84.5%{transform:translate(469.56559px,344.879997px)}}@keyframes be-u-el2-c1b-s16_to__to{0%,90.5%,to{transform:translate(469.56559px,412.879997px)}37.75%{transform:translate(469.56559px,412.879997px);animation-timing-function:cubic-bezier(.42,0,.23,.995)}42.75%,84.5%{transform:translate(469.56559px,435.879997px)}}@keyframes be-u-ellipse-yellow3_c_o{0%,28%,63%,to{opacity:0}31%,60%{opacity:1}}@keyframes be-u-ellipse-bluel-c1-s13_c_o{0%,28%,63%,to{opacity:1}31%,60%{opacity:0}}@keyframes be-u-eye-lid13_to__to{0%,28%,63%,to{transform:translate(224.205292px,367.765588px)}31%,60%{transform:translate(224.205292px,347.765588px)}}@keyframes be-u-eye-lid23_to__to{0%,28%,63%,to{transform:translate(224.205292px,395.765588px)}31%,60%{transform:translate(224.205292px,415.765588px)}}@keyframes be-u-ellipse-yellow4_c_o{0%,28%,63%,to{opacity:0}31%,60%{opacity:1}}@keyframes be-u-ellipse-bluel-c1-s14_c_o{0%,28%,63%,to{opacity:1}31%,60%{opacity:0}}@keyframes be-u-eye-lid14_to__to{0%,28%,63%,to{transform:translate(224.205292px,367.765588px)}31%,60%{transform:translate(224.205292px,347.765588px)}}@keyframes be-u-eye-lid24_to__to{0%,28%,63%,to{transform:translate(224.205292px,395.765588px)}31%,60%{transform:translate(224.205292px,415.765588px)}}@keyframes be-u-eye-off_c_o{0%,38%,38.2%,38.3%,38.5%,90.5%,to{opacity:1}38.1%,38.4%,39%,88.5%{opacity:0}}@keyframes be-u-eye-off2_c_o{0%,38%,38.2%,38.3%,38.5%,90.5%,to{opacity:1}38.1%,38.4%,39%,88.5%{opacity:0}}";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library ConveyorBeltCSS1 {
  string internal constant PART = "@keyframes cb-u-c-mineral-c_to__to{0%{transform:translate(305.596907px,127.822064px)}5%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c2_to__to{0%,15%{transform:translate(305.596907px,127.822064px)}20%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c3_to__to{0%,25%{transform:translate(305.596907px,127.822064px)}30%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c4_to__to{0%,40%{transform:translate(305.596907px,127.822064px)}45%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c5_to__to{0%,15%{transform:translate(305.596907px,127.822064px)}34%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c6_to__to{0%,14%{transform:translate(305.596907px,127.822064px)}49%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c7_to__to{0%,48%{transform:translate(305.596907px,127.822064px)}82%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-c-mineral-c8_to__to{0%,12%{transform:translate(305.596907px,127.822064px)}82%,to{transform:translate(165.596907px,208.822064px)}}@keyframes cb-u-ha_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha2_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha3_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha4_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha5_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha6_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha7_ts__ts{0%,12%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12.05%{transform:translate(312.476471px,899.496277px) scale(1,1);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha8_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-ha9_ts__ts{0%,96%,to{transform:translate(312.476471px,899.496277px) scale(.75,.75)}12%{transform:translate(312.476471px,899.496277px) scale(.75,.75);animation-timing-function:cubic-bezier(.42,0,.58,1)}19%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3)}88%{transform:translate(312.476471px,899.496277px) scale(2.3,2.3);animation-timing-function:cubic-bezier(.42,0,.58,1)}}@keyframes cb-u-lines-anim_to__to{0%{offset-distance:0}12%{offset-distance:0;animation-timing-function:cubic-bezier(.42,0,1,1)}17.05%{offset-distance:.683702%}17.1%{offset-distance:1.315789%}18%{offset-distance:1.999491%}18.05%{offset-distance:2.631579%}19%{offset-distance:3.315281%}19.05%{offset-distance:3.947368%}19.95%{offset-distance:4.63107%}20%{offset-distance:5.263158%}20.95%{offset-distance:5.94686%}21%{offset-distance:6.578947%}21.9%{offset-distance:7.262649%}21.95%{offset-distance:7.894737%}22.9%{offset-distance:8.578439%}22.95%{offset-distance:9.210526%}23.85%{offset-distance:9.894228%}23.9%{offset-distance:10.526316%}24.85%{offset-distance:11.210018%}24.9%{offset-distance:11.842105%}25.8%{offset-distance:12.525807%}25.85%{offset-distance:13.157895%}26.8%{offset-distance:13.841597%}26.85%{offset-distance:14.473684%}27.75%{offset-distance:15.157386%}27.8%{offset-distance:15.789474%}28.75%{offset-distance:16.473176%}28.8%{offset-distance:17.105263%}29.7%{offset-distance:17.788965%}29.75%{offset-distance:18.421053%}30.7%{offset-distance:19.104755%}30.75%{offset-distance:19.736842%}31.65%{offset-distance:20.420544%}31.7%{offset-distance:21.052632%}32.65%{offset-distance:21.736333%}32.7%{offset-distance:22.368421%}33.6%{offset-distance:23.052123%}33.65%{offset-distance:23.684211%}34.6%{offset-distance:24.367912%}34.65%{offset-distance:25%}35.55%{offset-distance:25.683702%}35.6%{offset-distance:26.315789%}36.55%{offset-distance:26.999491%}36.6%{offset-distance:27.631579%}37.5%{offset-distance:28.315281%}37.55%{offset-distance:28.947368%}38.5%{offset-distance:29.63107%}38.55%{offset-distance:30.263158%}39.45%{offset-distance:30.94686%}39.5%{offset-distance:31.578947%}40.45%{offset-distance:32.262649%}40.5%{offset-distance:32.894737%}41.4%{offset-distance:33.578439%}41.45%{offset-distance:34.210526%}42.4%{offset-distance:34.894228%}42.45%{offset-distance:35.526316%}43.35%{offset-distance:36.210018%}43.4%{offset-distance:36.842105%}44.35%{offset-distance:37.525807%}44.4%{offset-distance:38.157895%}45.3%{offset-distance:38.841597%}45.35%{offset-distance:39.473684%}46.3%{offset-distance:40.157386%}46.35%{offset-distance:40.789474%}47.25%{offset-distance:41.473176%}47.3%{offset-distance:42.105263%}48.25%{offset-distance:42.788965%}48.3%{offset-distance:43.421053%}49.2%{offset-distance:44.104755%}49.25%{offset-distance:44.736842%}50.2%{offset-distance:45.420544%}50.25%{offset-distance:46.052632%}51.15%{offset-distance:46.736333%}51.2%{offset-distance:47.368421%}52.15%{offset-distance:48.052123%}52.2%{offset-distance:48.684211%}53.1%{offset-distance:49.367912%}53.15%{offset-distance:50%}54.1%{offset-distance:50.683702%}54.15%{offset-distance:51.315789%}55.05%{offset-distance:51.999491%}55.1%{offset-distance:52.631579%}56.05%{offset-distance:53.315281%}56.1%{offset-distance:53.947368%}57%{offset-distance:54.63107%}57.05%{offset-distance:55.263158%}58%{offset-distance:55.94686%}58.05%{offset-distance:56.578947%}58.95%{offset-distance:57.262649%}59%{offset-distance:57.894737%}59.95%{offset-distance:58.578439%}60%{offset-distance:59.210526%}60.9%{offset-distance:59.894228%}60.95%{offset-distance:60.526316%}61.9%{offset-distance:61.210018%}61.95%{offset-distance:61.842105%}62.85%{offset-distance:62.525807%}62.9%{offset-distance:63.157895%}63.85%{offset-distance:63.841597%}63.9%{offset-distance:64.473684%}64.8%{offset-distance:65.157386%}64.85%{offset-distance:65.789474%}65.8%{offset-distance:66.473176%}65.85%{offset-distance:67.105263%}66.75%{offset-distance:67.788965%}66.8%{offset-distance:68.421053%}67.75%{offset-distance:69.104755%}67.8%{offset-distance:69.736842%}68.7%{offset-distance:70.420544%}68.75%{offset-distance:71.052632%}69.7%{offset-distance:71.736333%}69.75%{offset-distance:72.368421%}70.65%{offset-distance:73.052123%}70.7%{offset-distance:73.684211%}71.65%{offset-distance:74.367912%}71.7%{offset-distance:75%}72.6%{offset-distance:75.683702%}72.65%{offset-distance:76.315789%}73.6%{offset-distance:76.999491%}73.65%{offset-distance:77.631579%}74.55%{offset-distance:78.315281%}74.6%{offset-distance:78.947368%}75.55%{offset-distance:79.63107%}75.6%{offset-distance:80.263158%}76.5%{offset-distance:80.94686%}76.55%{offset-distance:81.578947%}77.5%{offset-distance:82.262649%}77.55%{offset-distance:82.894737%}78.45%{offset-distance:83.578439%}78.5%{offset-distance:84.210526%}79.45%{offset-distance:84.894228%}79.5%{offset-distance:85.526316%}80.4%{offset-distance:86.210018%}80.45%{offset-distance:86.842105%}81.4%{offset-distance:87.525807%}81.45%{offset-distance:88.157895%}82.35%{offset-distance:88.841597%}82.4%{offset-distance:89.473684%}83.35%{offset-distance:90.157386%}83.4%{offset-distance:90.789474%}84.3%{offset-distance:91.473176%}84.35%{offset-distance:92.105263%}85.3%{offset-distance:92.788965%}85.35%{offset-distance:93.421053%}86.25%{offset-distance:94.104755%}86.3%{offset-distance:94.736842%}87.25%{offset-distance:95.420544%}87.3%{offset-distance:96.052632%}88.2%{offset-distance:96.736333%}88.25%{offset-distance:97.368421%}89.2%{offset-distance:98.052123%}89.25%{offset-distance:98.684211%}91.95%{offset-distance:99.367912%}92%,to{offset-distance:100%}}@keyframes cb-u-dl4_to__to{0%{transform:translate(-1091.105011px,1487.490005px)}12%{transform:translate(-1091.105011px,1487.490005px);animation-timing-function:cubic-bezier(.15,0,.85,1)}92%,to{transform:translate(668.894989px,519.490005px)}}@keyframes cb-u-lines-anim2_to__to{0%{offset-distance:0}12%{offset-distance:0;animation-timing-function:cubic-bezier(.15,0,.85,1)}17.05%{offset-distance:.683702%}17.1%{offset-distance:1.315789%}18%{offset-distance:1.999491%}18.05%{offset-distance:2.631579%}19%{offset-distance:3.315281%}19.05%{offset-distance:3.947368%}19.95%{offset-distance:4.63107%}20%{offset-distance:5.263158%}20.95%{offset-distance:5.94686%}21%{offset-distance:6.578947%}21.9%{offset-distance:7.262649%}21.95%{offset-distance:7.894737%}22.9%{offset-distance:8.578439%}22.95%{offset-distance:9.210526%}23.85%{offset-distance:9.894228%}23.9%{offset-distance:10.526316%}24.85%{offset-distance:11.210018%}24.9%{offset-distance:11.842105%}25.8%{offset-distance:12.525807%}25.85%{offset-distance:13.157895%}26.8%{offset-distance:13.841597%}26.85%{offset-distance:14.473684%}27.75%{offset-distance:15.157386%}27.8%{offset-distance:15.789474%}28.75%{offset-distance:16.473176%}28.8%{offset-distance:17.105263%}29.7%{offset-distance:17.788965%}29.75%{offset-distance:18.421053%}30.7%{offset-distance:19.104755%}30.75%{offset-distance:19.736842%}31.65%{offset-distance:20.420544%}31.7%{offset-distance:21.052632%}32.65%{offset-distance:21.736333%}32.7%{offset-distance:22.368421%}33.6%{offset-distance:23.052123%}33.65%{offset-distance:23.684211%}34.6%{offset-distance:24.367912%}34.65%{offset-distance:25%}35.55%{offset-distance:25.683702%}35.6%{offset-distance:26.315789%}36.55%{offset-distance:26.999491%}36.6%{offset-distance:27.631579%}37.5%{offset-distance:28.315281%}37.55%{offset-distance:28.947368%}38.5%{offset-distance:29.63107%}38.55%{offset-distance:30.263158%}39.45%{offset-distance:30.94686%}39.5%{offset-distance:31.578947%}40.45%{offset-distance:32.262649%}40.5%{offset-distance:32.894737%}41.4%{offset-distance:33.578439%}41.45%{offset-distance:34.210526%}42.4%{offset-distance:34.894228%}42.45%{offset-distance:35.526316%}43.35%{offset-distance:36.210018%}43.4%{offset-distance:36.842105%}44.35%{offset-distance:37.525807%}44.4%{offset-distance:38.157895%}45.3%{offset-distance:38.841597%}45.35%{offset-distance:39.473684%}46.3%{offset-distance:40.157386%}46.35%{offset-distance:40.789474%}47.25%{offset-distance:41.473176%}47.3%{offset-distance:42.105263%}48.25%{offset-distance:42.788965%}48.3%{offset-distance:43.421053%}49.2%{offset-distance:44.104755%}49.25%{offset-distance:44.736842%}50.2%{offset-distance:45.420544%}50.25%{offset-distance:46.052632%}51.15%{offset-distance:46.736333%}51.2%{offset-distance:47.368421%}52.15%{offset-distance:48.052123%}52.2%{offset-distance:48.684211%}53.1%{offset-distance:49.367912%}53.15%{offset-distance:50%}54.1%{offset-distance:50.683702%}54.15%{offset-distance:51.315789%}55.05%{offset-distance:51.999491%}55.1%{offset-distance:52.631579%}56.05%{offset-distance:53.315281%}56.1%{offset-distance:53.947368%}57%{offset-distance:54.63107%}57.05%{offset-distance:55.263158%}58%{offset-distance:55.94686%}58.05%{offset-distance:56.578947%}58.95%{offset-distance:57.262649%}59%{offset-distance:57.894737%}59.95%{offset-distance:58.578439%}60%{offset-distance:59.210526%}60.9%{offset-distance:59.894228%}60.95%{offset-distance:60.526316%}61.9%{offset-distance:61.210018%}61.95%{offset-distance:61.842105%}62.85%{offset-distance:62.525807%}62.9%{offset-distance:63.157895%}63.85%{offset-distance:63.841597%}63.9%{offset-distance:64.473684%}64.8%{offset-distance:65.157386%}64.85%{offset-distance:65.789474%}65.8%{offset-distance:66.473176%}65.85%{offset-distance:67.105263%}66.75%{offset-distance:67.788965%}66.8%{offset-distance:68.421053%}67.75%{offset-distance:69.104755%}67.8%{offset-distance:69.736842%}68.7%{offset-distance:70.420544%}68.75%{offset-distance:71.052632%}69.7%{offset-distance:71.736333%}69.75%{offset-distance:72.368421%}70.65%{offset-distance:73.052123%}70.7%{offset-distance:73.684211%}71.65%{offset-distance:74.367912%}71.7%{offset-distance:75%}72.6%{offset-distance:75.683702%}72.65%{offset-distance:76.315789%}73.6%{offset-distance:76.999491%}73.65%{offset-distance:77.631579%}74.55%{offset-distance:78.315281%}74.6%{offset-distance:78.947368%}75.55%{offset-distance:79.63107%}75.6%{offset-distance:80.263158%}76.5%{offset-distance:80.94686%}76.55%{offset-distance:81.578947%}77.5%{offset-distance:82.262649%}77.55%{offset-distance:82.894737%}78.45%{offset-distance:83.578439%}78.5%{offset-distance:84.210526%}79.45%{offset-distance:84.894228%}79.5%{offset-distance:85.526316%}80.4%{offset-distance:86.210018%}80.45%{offset-distance:86.842105%}81.4%{offset-distance:87.525807%}81.45%{offset-distance:88.157895%}82.35%{offset-distance:88.841597%}82.4%{offset-distance:89.473684%}83.35%{offset-distance:90.157386%}83.4%{offset-distance:90.789474%}84.3%{offset-distance:91.473176%}84.35%{offset-distance:92.105263%}85.3%{offset-distance:92.788965%}85.35%{offset-distance:93.421053%}86.25%{offset-distance:94.104755%}86.3%{offset-distance:94.736842%}87.25%{offset-distance:95.420544%}87.3%{offset-distance:96.052632%}88.2%{offset-distance:96.736333%}88.25%{offset-distance:97.368421%}89.2%{offset-distance:98.052123%}89.25%{offset-distance:98.684211%}91.95%{offset-distance:99.367912%}92%,to{offset-distance:100%}}@keyframes cb-u-dl42_to__to{0%{transform:translate(-1091.105011px,1487.490005px)}12%{transform:translate(-1091.105011px,1487.490005px);animation-timing-function:cubic-bezier(.15,0,.85,1)}92%,to{";

  function getPart() external pure returns (string memory) {
    return PART;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library ConveyorBeltCSS2 {
  string internal constant PART = "transform:translate(668.894989px,519.490005px)}}@keyframes cb-u-ld4_to__to{0%{transform:translate(-1553.899963px,1788.749985px)}13%{transform:translate(-1553.899963px,1788.749985px);animation-timing-function:cubic-bezier(.15,0,.85,1)}93%,to{transform:translate(858.100037px,406.749985px)}}@keyframes cb-u-ld42_to__to{0%{transform:translate(-1553.899963px,1788.749985px)}13%{transform:translate(-1553.899963px,1788.749985px);animation-timing-function:cubic-bezier(.15,0,.85,1)}93%,to{transform:translate(857.100037px,406.749985px)}}@keyframes cb-u-floob-reverse-p5to4_to__to{0%,24.2%{offset-distance:0}29%{offset-distance:13.548%}38%{offset-distance:21.613%}42.8%{offset-distance:35.161%}51.1%{offset-distance:43.226%}54.8%{offset-distance:56.774%}65%{offset-distance:64.839%}68.7%{offset-distance:78.387%}79.05%{offset-distance:86.452%}82.75%,to{offset-distance:100%}}@keyframes cb-u-floob-reverse-p5to4_ts__ts{0%,27%,29.5%,41%,53%,66.9%,80.95%{transform:scale(1,1)}29%,43%,55%,68.9%,82.95%,to{transform:scale(.6,.6)}}@keyframes cb-u-floob-reverse-p5to4_c_o{0%,24.2%,29.5%,38.15%,43.05%,51.05%,54.85%,64.95%,69%,79%{opacity:0}24.25%,29%,38.2%,43%,51.1%,54.8%,65%,68.95%,79.05%,to{opacity:1}}@keyframes cb-u-floob-reverse-p5to42_to__to{0%,24.2%{offset-distance:0}29%{offset-distance:13.548%}38%{offset-distance:21.613%}42.8%{offset-distance:35.161%}51.1%{offset-distance:43.226%}54.8%{offset-distance:56.774%}65%{offset-distance:64.839%}68.7%{offset-distance:78.387%}79.05%{offset-distance:86.452%}82.75%,to{offset-distance:100%}}@keyframes cb-u-floob-reverse-p5to42_ts__ts{0%,27%,29.5%,41%,53%,66.9%,80.95%{transform:scale(1,1)}29%,43%,55%,68.9%,82.95%,to{transform:scale(.6,.6)}}@keyframes cb-u-floob-reverse-p5to42_c_o{0%,24.25%,29.5%,38.15%,43.05%,51.05%,54.85%,64.95%,69%,79%{opacity:0}24.3%,29%,38.2%,43%,51.1%,54.8%,65%,68.95%,79.05%,to{opacity:1}}@keyframes cb-u-floob-reverse-p5to3_to__to{0%,24%{offset-distance:0}24.25%{offset-distance:.254402%}29.5%{offset-distance:6.876238%}31%{offset-distance:12.238035%}38%{offset-distance:14.737925%}38.1%{offset-distance:22.20059%}43.6%{offset-distance:28.843693%}45.1%{offset-distance:34.197201%}50.9%{offset-distance:36.675108%}51%{offset-distance:44.15212%}57.5%{offset-distance:50.795224%}59%{offset-distance:56.10606%}64.8%{offset-distance:58.591335%}64.9%{offset-distance:66.078959%}71.5%{offset-distance:72.722063%}73%{offset-distance:78.054217%}78.85%{offset-distance:80.532776%}78.95%{offset-distance:88.008441%}85.5%{offset-distance:94.651545%}87%,to{offset-distance:100%}}@keyframes cb-u-floob-reverse-p5to3_ts__ts{0%,29.5%,31.05%,43.6%,45.15%,57.5%,59.05%,71.5%,73.05%,85.5%,87.05%,to{transform:scale(1,1)}30.55%,31%,44.65%,45.1%,58.55%,59%,72.55%,73%,86.55%,87%{transform:scale(.8,.8)}}@keyframes cb-u-floob-reverse-p5to3_c_o{0%,24.25%,31.05%,38%,38.15%,45.15%,50.9%,51.05%,59.05%,64.8%,64.95%,73.05%,78.85%,79%,87.05%,to{opacity:0}24.3%,31%,38.2%,45.1%,51.1%,59%,65%,73%,79.05%,87%{opacity:1}}@keyframes cb-u-floob-p5f3-rev-pl_to__to{0%,24%{offset-distance:0}24.25%{offset-distance:.254402%}29.5%{offset-distance:6.876238%}31%{offset-distance:12.238035%}38%{offset-distance:14.737925%}38.1%{offset-distance:22.20059%}43.6%{offset-distance:28.843693%}45.1%{offset-distance:34.197201%}50.9%{offset-distance:36.675108%}51%{offset-distance:44.15212%}57.5%{offset-distance:50.795224%}59%{offset-distance:56.10606%}64.8%{offset-distance:58.591335%}64.9%{offset-distance:66.078959%}71.5%{offset-distance:72.722063%}73%{offset-distance:78.054217%}78.85%{offset-distance:80.532776%}78.95%{offset-distance:88.008441%}85.5%{offset-distance:94.651545%}87%,to{offset-distance:100%}}@keyframes cb-u-floob-p5f3-rev-pl_ts__ts{0%,29.5%,31.05%,43.6%,45.15%,57.5%,59.05%,71.5%,73.05%,85.5%,87.05%,to{transform:scale(1,1)}30.55%,31%,44.65%,45.1%,58.55%,59%,72.55%,73%,86.55%,87%{transform:scale(.8,.8)}}@keyframes cb-u-floob-p5f3-rev-pl_c_o{0%,24.25%,31.05%,38%,38.15%,45.15%,50.9%,51.05%,59.05%,64.8%,64.95%,73.05%,78.85%,79%,87.05%,to{opacity:0}24.3%,31%,38.2%,45.1%,51.1%,59%,65%,73%,79.05%,87%{opacity:1}}@keyframes cb-u-floob-reverse-p4to3_to__to{0%,22%{offset-distance:0}23.5%{offset-distance:3.136786%}25%{offset-distance:10.147728%}36.05%{offset-distance:22.354512%}37.55%{offset-distance:25.491298%}39.05%{offset-distance:32.50224%}48.4%{offset-distance:44.858666%}49.55%{offset-distance:47.995453%}51.05%{offset-distance:55.006395%}62.85%{offset-distance:67.151394%}63.5%{offset-distance:70.28818%}65.05%{offset-distance:77.299122%}77.5%{offset-distance:89.852272%}78.95%{offset-distance:92.989058%}80.45%,to{offset-distance:100%}}@keyframes cb-u-floob-reverse-p4to3_ts__ts{0%,23.5%,37.55%,49.55%,63.6%,78.95%{transform:scale(1,1)}25.1%,25.15%,39%,39.05%,51.05%,51.1%,65.05%,65.1%,80.4%,80.45%,to{transform:scale(.78,.78)}}@keyframes cb-u-floob-reverse-p4to3_c_o{0%,22%,25.15%,36%,39.05%,48.35%,51.1%,62.85%,65.1%,77.4%,80.45%,to{opacity:0}22.05%,25.1%,36.05%,39%,48.4%,51.05%,62.9%,65.05%,77.45%,80.4%{opacity:1}}@keyframes cb-u-floob-reverse-p4to32_to__to{0%,22%{offset-distance:0}23.5%{offset-distance:3.372941%}25%{offset-distance:10.646578%}36.05%{offset-distance:22.300524%}37.55%{offset-distance:25.666609%}39%{offset-distance:32.807461%}39.05%{offset-distance:32.907557%}48.4%{offset-distance:44.626562%}49.55%{offset-distance:47.973758%}51.05%{offset-distance:55.231398%}62.85%{offset-distance:66.844917%}63.5%{offset-distance:70.26527%}65.05%{offset-distance:77.472032%}77.5%{offset-distance:89.335861%}78.95%{offset-distance:92.738088%}80.45%,to{offset-distance:100%}}@keyframes cb-u-floob-reverse-p4to32_ts__ts{0%,23.4%,25.9%,37.5%,42%,49.5%,54%,63.5%,68%,79%,81.5%,to{transform:scale(1,1)}25%,39%,51%,65%,80.5%{transform:scale(.8,.8)}}@keyframes cb-u-floob-reverse-p4to32_c_o{0%,22%,25.15%,36%,39.05%,48.35%,51.1%,62.85%,65.1%,77.4%,80.45%,to{opacity:0}22.05%,25.1%,36.05%,39%,48.4%,51.05%,62.9%,65.05%,77.45%,80.4%{opacity:1}}@keyframes cb-u-lines-anim3_to__to{0%{offset-distance:0}12%{offset-distance:0;animation-timing-function:cubic-bezier(.15,0,.85,1)}17.05%{offset-distance:.683702%}17.1%{offset-distance:1.315789%}18%{offset-distance:1.999491%}18.05%{offset-distance:2.631579%}19%{offset-distance:3.315281%}19.05%{offset-distance:3.947368%}19.95%{offset-distance:4.63107%}20%{offset-distance:5.263158%}20.95%{offset-distance:5.94686%}21%{offset-distance:6.578947%}21.9%{offset-distance:7.262649%}21.95%{offset-distance:7.894737%}22.9%{offset-distance:8.578439%}22.95%{offset-distance:9.210526%}23.85%{offset-distance:9.894228%}23.9%{offset-distance:10.526316%}24.85%{offset-distance:11.210018%}24.9%{offset-distance:11.842105%}25.8%{offset-distance:12.525807%}25.85%{offset-distance:13.157895%}26.8%{offset-distance:13.841597%}26.85%{offset-distance:14.473684%}27.75%{offset-distance:15.157386%}27.8%{offset-distance:15.789474%}28.75%{offset-distance:16.473176%}28.8%{offset-distance:17.105263%}29.7%{offset-distance:17.788965%}29.75%{offset-distance:18.421053%}30.7%{offset-distance:19.104755%}30.75%{offset-distance:19.736842%}31.65%{offset-distance:20.420544%}31.7%{offset-distance:21.052632%}32.65%{offset-distance:21.736333%}32.7%{offset-distance:22.368421%}33.6%{offset-distance:23.052123%}33.65%{offset-distance:23.684211%}34.6%{offset-distance:24.367912%}34.65%{offset-distance:25%}35.55%{offset-distance:25.683702%}35.6%{offset-distance:26.315789%}36.55%{offset-distance:26.999491%}36.6%{offset-distance:27.631579%}37.5%{offset-distance:28.315281%}37.55%{offset-distance:28.947368%}38.5%{offset-distance:29.63107%}38.55%{offset-distance:30.263158%}39.45%{offset-distance:30.94686%}39.5%{offset-distance:31.578947%}40.45%{offset-distance:32.262649%}40.5%{offset-distance:32.894737%}41.4%{offset-distance:33.578439%}41.45%{offset-distance:34.210526%}42.4%{offset-distance:34.894228%}42.45%{offset-distance:35.526316%}43.35%{offset-distance:36.210018%}43.4%{offset-distance:36.842105%}44.35%{offset-distance:37.525807%}44.4%{offset-distance:38.157895%}45.3%{offset-distance:38.841597%}45.35%{offset-distance:39.473684%}46.3%{offset-distance:40.157386%}46.35%{offset-distance:40.789474%}47.25%{offset-distance:41.473176%}47.3%{offset-distance:42.105263%}48.25%{offset-distance:42.788965%}48.3%{offset-distance:43.421053%}49.2%{offset-distance:44.104755%}49.25%{offset-distance:44.736842%}50.2%{offset-distance:45.420544%}50.25%{offset-distance:46.052632%}51.15%{offset-distance:46.736333%}51.2%{offset-distance:47.368421%}52.15%{offset-distance:48.052123%}52.2%{offset-distance:48.684211%}53.1%{offset-distance:49.367912%}53.15%{offset-distance:50%}54.1%{offset-distance:50.683702%}54.15%{offset-distance:51.315789%}55.05%{offset-distance:51.999491%}55.1%{offset-distance:52.631579%}56.05%{offset-distance:53.315281%}56.1%{offset-distance:53.947368%}57%{offset-distance:54.63107%}57.05%{offset-distance:55.263158%}58%{offset-distance:55.94686%}58.05%{offset-distance:56.578947%}58.95%{offset-distance:57.262649%}59%{offset-distance:57.894737%}59.95%{offset-distance:58.578439%}60%{offset-distance:59.210526%}60.9%{offset-distance:59.894228%}60.95%{offset-distance:60.526316%}61.9%{offset-distance:61.210018%}61.95%{offset-distance:61.842105%}62.85%{offset-distance:62.525807%}62.9%{offset-distance:63.157895%}63.85%{offset-distance:63.841597%}63.9%{offset-distance:64.473684%}64.8%{offset-distance:65.157386%}64.85%{offset-distance:65.789474%}65.8%{offset-distance:66.473176%}65.85%{offset-distance:67.105263%}66.75%{offset-distance:67.788965%}66.8%{offset-distance:68.421053%}67.75%{offset-distance:69.104755%}67.8%{offset-distance:69.736842%}68.7%{offset-distance:70.420544%}68.75%{offset-distance:71.052632%}69.7%{offset-distance:71.736333%}69.75%{offset-distance:72.368421%}70.65%{offset-distance:73.052123%}70.7%{offset-distance:73.684211%}71.65%{offset-distance:74.367912%}71.7%{offset-distance:75%}72.6%{offset-distance:75.683702%}72.65%{offset-distance:76.315789%}73.6%{offset-distance:76.999491%}73.65%{offset-distance:77.631579%}74.55%{offset-distance:78.315281%}74.6%{offset-distance:78.947368%}75.55%{offset-distance:79.63107%}75.6%{offset-distance:80.263158%}76.5%{offset-distance:80.94686%}76.55%{offset-distance:81.578947%}77.5%{offset-distance:82.262649%}77.55%{offset-distance:82.894737%}78.45%{offset-distance:83.578439%}78.5%{offset-distance:84.210526%}79.45%{offset-distance:84.894228%}79.5%{offset-distance:85.526316%}80.4%{offset-distance:86.210018%}80.45%{offset-distance:86.842105%}81.4%{offset-distance:87.525807%}81.45%{offset-distance:88.157895%}82.35%{offset-distance:88.841597%}82.4%{offset-distance:89.473684%}83.35%{offset-distance:90.157386%}83.4%{offset-distance:90.789474%}84.3%{offset-distance:91.473176%}84.35%{offset-distance:92.105263%}85.3%{offset-distance:92.788965%}85.35%{offset-distance:93.421053%}86.25%{offset-distance:94.104755%}86.3%{offset-distance:94.736842%}87.25%{offset-distance:95.420544%}87.3%{offset-distance:96.052632%}88.2%{offset-distance:96.736333%}88.25%{offset-distance:97.368421%}89.2%{offset-distance:98.052123%}89.25%{offset-distance:98.684211%}91.95%{offset-distance:99.367912%}92%,to{offset-distance:100%}}@keyframes cb-u-dl43_to__to{0%{transform:translate(668.894989px,519.490005px)}12%{transform:translate(668.894989px,519.490005px);animation-timing-function:cubic-bezier(.155,-.005,.805,1)}92%,to{transform:translate(-1091.105011px,1487.490005px)}}@keyframes cb-u-lines-anim4_to__to{0%{offset-distance:0}12%{offset-distance:0;animation-timing-function:cubic-bezier(.15,0,.85,1)}17.05%{offset-distance:.683702%}17.1%{offset-distance:1.315789%}18%{offset-distance:1.999491%}18.05%{offset-distance:2.631579%}19%{offset-distance:3.315281%}19.05%{offset-distance:3.947368%}19.95%{offset-distance:4.63107%}20%{offset-distance:5.263158%}20.95%{offset-distance:5.94686%}21%{offset-distance:6.578947%}21.9%{offset-distance:7.262649%}21.95%{offset-distance:7.894737%}22.9%{offset-distance:8.578439%}22.95%{offset-distance:9.210526%}23.85%{offset-distance:9.894228%}23.9%{offset-distance:10.526316%}24.85%{offset-distance:11.210018%}24.9%{offset-distance:11.842105%}25.8%{offset-distance:12.525807%}25.85%{offset-distance:13.157895%}26.8%{offset-distance:13.841597%}26.85%{offset-distance:14.473684%}27.75%{offset-distance:15.157386%}27.8%{offset-distance:15.789474%}28.75%{offset-distance:16.473176%}28.8%{offset-distance:17.105263%}29.7%{offset-distance:17.788965%}29.75%{offset-distance:18.421053%}30.7%{offset-distance:19.104755%}30.75%{offset-distance:19.736842%}31.65%{offset-distance:20.420544%}31.7%{offset-distance:21.052632%}32.65%{offset-distance:21.736333%}32.7%{offset-distance:22.368421%}33.6%{offset-distance:23.052123%}33.65%{offset-distance:23.684211%}34.6%{offset-distance:24.367912%}34.65%{offset-distance:25%}35.55%{offset-distance:25.683702%}35.6%{offset-distance:26.315789%}36.55%{offset-distance:26.999491%}36.6%{offset-distance:27.631579%}37.5%{offset-distance:28.315281%}37.55%{offset-distance:28.947368%}38.5%{offset-distance:29.63107%}38.55%{offset-distance:30.263158%}39.45%{offset-distance:30.94686%}39.5%{offset-distance:31.578947%}40.45%{offset-distance:32.262649%}40.5%{offset-distance:32.894737%}41.4%{offset-distance:33.578439%}41.45%{offset-distance:34.210526%}42.4%{offset-distance:34.894228%}42.45%{offset-distance:35.526316%}43.35%{offset-distance:36.210018%}43.4%{offset-distance:36.842105%}44.35%{offset-distance:37.525807%}44.4%{offset-distance:38.157895%}45.3%{offset-distance:38.841597%}45.35%{offset-distance:39.473684%}46.3%{offset-distance:40.157386%}46.35%{offset-distance:40.789474%}47.25%{offset-distance:41.473176%}47.3%{offset-distance:42.105263%}48.25%{offset-distance:42.788965%}48.3%{offset-distance:43.421053%}49.2%{offset-distance:44.104755%}49.25%{offset-distance:44.736842%}50.2%{offset-distance:45.420544%}50.25%{offset-distance:46.052632%}51.15%{offset-distance:46.736333%}51.2%{offset-distance:47.368421%}52.15%{offset-distance:48.052123%}52.2%{offset-distance:48.684211%}53.1%{offset-distance:49.367912%}53.15%{offset-distance:50%}54.1%{offset-distance:50.683702%}54.15%{offset-distance:51.315789%}55.05%{offset-distance:51.999491%}55.1%{offset-distance:52.631579%}56.05%{offset-distance:53.315281%}56.1%{offset-distance:53.947368%}57%{offset-distance:54.63107%}57.05%{offset-distance:55.263158%}58%{offset-distance:55.94686%}58.05%{offset-distance:56.578947%}58.95%{offset-distance:57.262649%}59%{offset-distance:57.894737%}59.95%{offset-distance:58.578439%}60%{offset-distance:59.210526%}60.9%{offset-distance:59.894228%}60.95%{offset-distance:60.526316%}61.9%{offset-distance:61.210018%}61.95%{offset-distance:61.842105%}62.85%{offset-distance:62.525807%}62.9%{offset-distance:63.157895%}63.85%{offset-distance:63.841597%}63.9%{offset-distance:64.473684%}64.8%{offset-distance:65.157386%}64.85%{offset-distance:65.789474%}65.8%{offset-distance:66.473176%}65.85%{offset-distance:67.105263%}66.75%{offset-distance:67.788965%}66.8%{offset-distance:68.421053%}67.75%{offset-distance:69.104755%}67.8%{offset-distance:69.736842%}68.7%{offset-distance:70.420544%}68.75%{offset-distance:71.052632%}69.7%{offset-distance:71.736333%}69.75%{offset-distance:72.368421%}70.65%{offset-distance:73.052123%}70.7%{offset-distance:73.684211%}71.65%{offset-distance:74.367912%}71.7%{offset-distance:75%}72.6%{offset-distance:75.683702%}72.65%{offset-distance:76.315789%}73.6%{offset-distance:76.999491%}73.65%{offset-distance:77.631579%}74.55%{offset-distance:78.315281%}74.6%{offset-distance:78.947368%}75.55%{offset-distance:79.63107%}75.6%{offset-distance:80.263158%}76.5%{offset-distance:80.94686%}76.55%{offset-distance:81.578947%}77";

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