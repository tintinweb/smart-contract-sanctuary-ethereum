//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";


contract DdRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}

    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        string memory flutedBezel = '<line x1="280.7" x2="283.4" y1="531.6" y2="500.7" stroke="#B3775C" stroke-width="14"/><line x1="266.75" x2="269.46" y1="530.38" y2="499.48" stroke="#E3C9B4" stroke-width="14"/><line x1="252.93" x2="258.58" y1="528.5" y2="498" stroke="#B3775C" stroke-width="14"/><line x1="239.17" x2="244.81" y1="525.95" y2="495.46" stroke="#E3C9B4" stroke-width="14"/><line x1="225.26" x2="235.11" y1="522.1" y2="492.69" stroke="#B3775C" stroke-width="14"/><line x1="211.98" x2="221.84" y1="517.65" y2="488.24" stroke="#E3C9B4" stroke-width="14"/><line x1="199.08" x2="213.08" y1="511.81" y2="484.13" stroke="#B3775C" stroke-width="14"/><line x1="186.59" x2="200.59" y1="505.49" y2="477.81" stroke="#E3C9B4" stroke-width="14"/><line x1="174.64" x2="192.47" y1="497.72" y2="472.34" stroke="#B3775C" stroke-width="14"/><line x1="163.18" x2="181.02" y1="489.66" y2="464.29" stroke="#E3C9B4" stroke-width="14"/><line x1="152.46" x2="173.2" y1="480.02" y2="456.96" stroke="#B3775C" stroke-width="14"/><line x1="142.05" x2="162.79" y1="470.66" y2="447.6" stroke="#E3C9B4" stroke-width="14"/><line x1="133.22" x2="156.27" y1="458.7" y2="437.94" stroke="#B3775C" stroke-width="14"/><line x1="123.85" x2="146.9" y1="448.29" y2="427.54" stroke="#E3C9B4" stroke-width="14"/><line x1="115.69" x2="141.73" y1="435.33" y2="418.48" stroke="#A97F6B" stroke-width="14"/><line x1="108.08" x2="134.12" y1="423.58" y2="406.72" stroke="#E3C9B4" stroke-width="14"/><line x1="101.18" x2="129.34" y1="410.42" y2="397.43" stroke="#A97F6B" stroke-width="14"/><line x1="95.316" x2="123.48" y1="397.7" y2="384.71" stroke="#E3C9B4" stroke-width="14"/><line x1="91.521" x2="121.23" y1="383.04" y2="374.14" stroke="#864441" stroke-width="14"/><line x1="87.5" x2="117.21" y1="369.63" y2="360.72" stroke="#E3C9B4" stroke-width="14"/><line x1="85.568" x2="116.4" y1="355.1" y2="351.76" stroke="#864441" stroke-width="14"/><line x1="84.063" x2="114.9" y1="341.18" y2="337.84" stroke="#E3C9B4" stroke-width="14"/><line x1="83.408" x2="114.42" y1="326.64" y2="327.33" stroke="#A97F6B" stroke-width="14"/><line x1="83.719" x2="114.73" y1="312.64" y2="313.33" stroke="#E3C9B4" stroke-width="14"/><line x1="85.241" x2="116.14" y1="298.68" y2="301.38" stroke="#B3775C" stroke-width="14"/><line x1="86.461" x2="117.36" y1="284.73" y2="287.44" stroke="#E3C9B4" stroke-width="14"/><line x1="302.84" x2="300.05" y1="117.96" y2="149.84" stroke="#B3775C" stroke-width="14"/><line x1="316.96" x2="314.17" y1="117.18" y2="149.06" stroke="#E3C9B4" stroke-width="14"/><line x1="330.57" x2="324.92" y1="122.04" y2="152.54" stroke="#B3775C" stroke-width="14"/><line x1="344.33" x2="338.69" y1="124.59" y2="155.09" stroke="#E3C9B4" stroke-width="14"/><line x1="358.24" x2="348.39" y1="128.45" y2="157.86" stroke="#B3775C" stroke-width="14"/><line x1="371.52" x2="361.66" y1="132.9" y2="162.3" stroke="#E3C9B4" stroke-width="14"/><line x1="384.42" x2="370.42" y1="138.73" y2="166.41" stroke="#A97F6B" stroke-width="14"/><line x1="396.91" x2="382.91" y1="145.05" y2="172.73" stroke="#E3C9B4" stroke-width="14"/><line x1="408.86" x2="391.02" y1="152.83" y2="178.2" stroke="#A97F6B" stroke-width="14"/><line x1="420.32" x2="402.48" y1="160.88" y2="186.25" stroke="#E3C9B4" stroke-width="14"/><line x1="431.04" x2="410.3" y1="170.52" y2="193.59" stroke="#A97F6B" stroke-width="14"/><line x1="441.45" x2="420.7" y1="179.89" y2="202.95" stroke="#E3C9B4" stroke-width="14"/><line x1="450.28" x2="427.23" y1="191.85" y2="212.6" stroke="#A97F6B" stroke-width="14"/><line x1="459.65" x2="436.6" y1="202.25" y2="223.01" stroke="#E3C9B4" stroke-width="14"/><line x1="467.81" x2="441.77" y1="215.21" y2="232.07" stroke="#C18270" stroke-width="14"/><line x1="475.42" x2="449.38" y1="226.97" y2="243.82" stroke="#E3C9B4" stroke-width="14"/><line x1="482.32" x2="454.16" y1="240.13" y2="253.12" stroke="#C18270" stroke-width="14"/><line x1="488.18" x2="460.02" y1="252.84" y2="265.83" stroke="#E3C9B4" stroke-width="14"/><line x1="491.98" x2="462.27" y1="267.5" y2="276.41" stroke="#A97F6B" stroke-width="14"/><line x1="496" x2="466.29" y1="280.91" y2="289.82" stroke="#E3C9B4" stroke-width="14"/><line x1="497.93" x2="467.1" y1="295.45" y2="298.78" stroke="#B3775C" stroke-width="14"/><line x1="499.44" x2="468.6" y1="309.37" y2="312.7" stroke="#E3C9B4" stroke-width="14"/><line x1="500.5" x2="469.6" y1="337.02" y2="334.31" stroke="#E3C9B4" stroke-width="14"/><line x1="500.09" x2="469.08" y1="323.9" y2="323.21" stroke="#B3775C" stroke-width="14"/><line x1="501.69" x2="467.35" y1="351.38" y2="348.57" stroke="#A97F6B" stroke-width="14"/><line x1="498.7" x2="467.14" y1="365.51" y2="360.21" stroke="#E3C9B4" stroke-width="14"/><line x1="494.76" x2="464.8" y1="379.02" y2="370.99" stroke="#B3775C" stroke-width="14"/><line x1="491.13" x2="461.17" y1="392.55" y2="384.51" stroke="#E3C9B4" stroke-width="14"/><line x1="486.19" x2="457.65" y1="406.11" y2="393.96" stroke="#B3775C" stroke-width="14"/><line x1="480.71" x2="452.17" y1="418.99" y2="406.84" stroke="#E3C9B4" stroke-width="14"/><line x1="473.87" x2="447.38" y1="431.39" y2="415.25" stroke="#B3775C" stroke-width="14"/><line x1="466.58" x2="440.1" y1="443.35" y2="427.21" stroke="#E3C9B4" stroke-width="14"/><line x1="457.89" x2="434" y1="454.65" y2="434.86" stroke="#B3775C" stroke-width="14"/><line x1="448.96" x2="425.07" y1="465.43" y2="445.64" stroke="#E3C9B4" stroke-width="14"/><line x1="438.5" x2="417.14" y1="475.35" y2="452.86" stroke="#A97F6B" stroke-width="14"/><line x1="428.34" x2="406.99" y1="484.99" y2="462.5" stroke="#E3C9B4" stroke-width="14"/><line x1="415.72" x2="396.85" y1="492.85" y2="468.24" stroke="#A97F6B" stroke-width="14"/><line x1="404.61" x2="385.74" y1="501.37" y2="476.76" stroke="#E3C9B4" stroke-width="14"/><line x1="391.05" x2="376.3" y1="508.48" y2="481.2" stroke="#B3775C" stroke-width="14"/><line x1="378.73" x2="363.98" y1="515.14" y2="487.86" stroke="#E3C9B4" stroke-width="14"/><line x1="365.06" x2="354.34" y1="520.99" y2="491.88" stroke="#B3775C" stroke-width="14"/><line x1="351.93" x2="341.2" y1="525.83" y2="496.72" stroke="#E3C9B4" stroke-width="14"/><line x1="337.02" x2="330.48" y1="528.46" y2="498.14" stroke="#A97F6B" stroke-width="14"/><line x1="323.33" x2="316.79" y1="531.41" y2="501.09" stroke="#E3C9B4" stroke-width="14"/><line x1="308.68" x2="307.79" y1="532.18" y2="501.18" stroke="#A97F6B" stroke-width="14"/><line x1="294.69" x2="293.8" y1="532.59" y2="501.58" stroke="#E3C9B4" stroke-width="14"/><line x1="280.15" x2="283.28" y1="532.09" y2="501.23" stroke="#B3775C" stroke-width="14"/><line transform="matrix(-.008237 .99997 .99997 .008237 307.37 117.48)" x2="32" y1="-7" y2="-7" stroke="#B3775C" stroke-width="14"/><line transform="matrix(-.008237 .99997 .99997 .008237 293.37 117.37)" x2="32" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.087375 .99618 .99618 -.087375 279.35 118.24)" x2="31.016" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><line transform="matrix(.087375 .99618 .99618 -.087375 265.4 119.46)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.22586 .97416 .97416 -.22586 251.03 121)" x2="31.016" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><line transform="matrix(.22586 .97416 .97416 -.22586 237.4 124.16)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.36427 .93129 .93129 -.36427 223.7 127.78)" x2="31.016" y1="-7" y2="-7" stroke="#7D5B49" stroke-width="14"/><line transform="matrix(.36427 .93129 .93129 -.36427 210.66 132.88)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.49454 .86915 .86915 -.49454 197.58 138.56)" x2="31.016" y1="-7" y2="-7" stroke="#7D5B49" stroke-width="14"/><line transform="matrix(.49454 .86915 .86915 -.49454 185.41 145.49)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.59476 .8039 .8039 -.59476 173.37 153.36)" x2="31.016" y1="-7" y2="-7" stroke="#B3775C" stroke-width="14"/><line transform="matrix(.59476 .8039 .8039 -.59476 162.11 161.69)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.67585 .73704 .73704 -.67585 151.71 172.19)" x2="31.016" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><line transform="matrix(.67585 .73704 .73704 -.67585 141.39 181.65)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.78379 .62103 .62103 -.78379 131.22 193.02)" x2="31.016" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><line transform="matrix(.78379 .62103 .62103 -.78379 122.53 203.99)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.86399 .50351 .50351 -.86399 113.58 215.88)" x2="31.016" y1="-7" y2="-7" stroke="#7D5B49" stroke-width="14"/><line transform="matrix(.86399 .50351 .50351 -.86399 106.53 227.97)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.9261 .37728 .37728 -.9261 100.47 241.77)" x2="31.016" y1="-7" y2="-7" stroke="#B3775C" stroke-width="14"/><line transform="matrix(.9261 .37728 .37728 -.9261 95.187 254.73)" x2="31.016" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.98083 .19489 .20925 -.97786 88.628 268.47)" x2="33.032" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><line transform="matrix(.98083 .19489 .20925 -.97786 85.697 282.18)" x2="33.032" y1="-7" y2="-7" stroke="#E3C9B4" stroke-width="14"/><line transform="matrix(.9962 .087156 .087156 -.9962 85.076 294.43)" x2="31.016" y1="-7" y2="-7" stroke="#A97F6B" stroke-width="14"/><circle transform="rotate(185 295.92 327.79)" cx="295.92" cy="327.79" r="215" stroke="#000" stroke-width="28"/>';
        string memory smoothBezel = '<circle transform="rotate(185 295.92 327.79)" cx="295.92" cy="327.79" r="215" fill="#FAFAFA" stroke="#000" stroke-width="28"/>';
        string memory partOne = '<rect transform="rotate(185 428.17 560.2)" x="428.17" y="560.2" width="37" height="45" fill="#ECC6B1"/><rect transform="rotate(185 163.18 537.01)" x="163.18" y="537.01" width="37" height="45" fill="#ECC6B1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 467.6 120.96)" width="37" height="45" fill="#ECC6B1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 202.61 97.779)" width="37" height="45" fill="#ECC6B1"/><rect transform="rotate(185 78.042 339.84)" x="78.042" y="339.84" width="42" height="75" fill="#ECC6B1"/><rect transform="rotate(185 316.82 616.71)" x="316.82" y="616.71" width="91" height="75" fill="#FBE2D4"/><rect transform="rotate(185 374.86 618.77)" x="374.86" y="618.77" width="47" height="80" fill="#ECC6B1"/><rect transform="rotate(185 211.48 604.48)" x="211.48" y="604.48" width="47" height="80" fill="#ECC6B1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 367.67 46.972)" width="91" height="72" fill="#FBE2D4"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 425.19 55.015)" width="47" height="77" fill="#ECC6B1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 261.81 40.722)" width="47" height="77" fill="#ECC6B1"/>';
        string memory partTwo = '<circle transform="rotate(185 292.93 327.53)" cx="292.93" cy="327.53" r="167" fill="#697F5C" stroke="#000" stroke-width="28"/><line x1="79.773" x2="23.986" y1="343.01" y2="338.13" stroke="#000" stroke-width="28"/><line x1="38.456" x2="46.212" y1="333.37" y2="244.71" stroke="#000" stroke-width="28"/><line x1="86.833" x2="47.777" y1="262.32" y2="258.9" stroke="#000" stroke-width="28"/><line x1="458.73" x2="418.52" y1="468.41" y2="572.3" stroke="#000" stroke-width="28"/><line transform="matrix(.1935 .9811 .9811 -.1935 124.9 435.29)" x2="111.4" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="429.71" x2="386.09" y1="564.05" y2="569.27" stroke="#000" stroke-width="28"/><line transform="matrix(.95721 .28939 .28939 -.95721 127.19 523.83)" x2="43.932" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="389.8" x2="366.74" y1="527.29" y2="641.71" stroke="#000" stroke-width="28"/><line transform="matrix(.024334 .9997 .9997 -.024334 184.81 507.79)" x2="116.73" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="313.7" x2="320.93" y1="629.48" y2="546.8" stroke="#000" stroke-width="28"/><line x1="221.22" x2="228.46" y1="619.39" y2="536.7" stroke="#000" stroke-width="28"/><line x1="369.47" x2="332.61" y1="577.15" y2="573.92" stroke="#000" stroke-width="28"/><line x1="315.62" x2="233.94" y1="584.48" y2="577.33" stroke="#000" stroke-width="28"/><line x1="215.06" x2="178.2" y1="563.64" y2="560.41" stroke="#000" stroke-width="28"/><line x1="380.88" x2="160.72" y1="630.34" y2="611.08" stroke="#000" stroke-width="28"/><line transform="matrix(-.1935 -.9811 -.9811 .1935 466.94 220.28)" x2="111.4" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="133.11" x2="173.32" y1="187.17" y2="83.275" stroke="#000" stroke-width="28"/><line transform="matrix(-.95721 -.28939 -.28939 .95721 464.65 131.75)" x2="43.932" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="162.14" x2="205.76" y1="91.525" y2="86.307" stroke="#000" stroke-width="28"/><line transform="matrix(-.024334 -.9997 -.9997 .024334 409.02 147.96)" x2="116.73" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="204.03" x2="227.09" y1="128.46" y2="14.035" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 379.76 34.98)" x2="83" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 286.94 28.866)" x2="83" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 410.43 108.94)" x2="37" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 358.68 92.36)" x2="82" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 256.02 95.425)" x2="37" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 430.9 58.526)" x2="221" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><rect transform="matrix(-.88944 .45704 -.47276 -.88119 363.19 452.27)" x="-.6811" y="-.21207" width="10.491" height="34.724" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(-.79657 -.60455 -.6186 .78571 383.8 216.18)" x="-.70758" y=".090579" width="10.491" height="34.724" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.9962 .087156 .10483 -.99449 315 228.12)" x=".55051" y="-.45367" width="10.005" height="35.006" fill="#F5C8BA" stroke="#7F584A"/><mask id="h" fill="white"><path d="m315.9 193.02-12.021 35.086-4.361-0.382-6.864-2.424 11.413-33.316 11.833 1.036z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m315.9 193.02-12.021 35.086-4.361-0.382-6.864-2.424 11.413-33.316 11.833 1.036z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m303.88 228.1-0.087 0.996 0.78 0.068 0.254-0.74-0.947-0.324zm12.021-35.086 0.946 0.324 0.414-1.209-1.273-0.112-0.087 0.997zm-16.382 34.704-0.333 0.943 0.119 0.042 0.126 0.011 0.088-0.996zm-6.864-2.424-0.946-0.324-0.321 0.937 0.934 0.33 0.333-0.943zm11.413-33.316 0.088-0.996-0.78-0.068-0.254 0.74 0.946 0.324zm0.759 36.446 12.02-35.086-1.892-0.648-12.021 35.086 1.893 0.648zm-5.396 0.29 4.362 0.382 0.175-1.992-4.362-0.382-0.175 1.992zm-7.109-2.477 6.864 2.424 0.666-1.886-6.864-2.424-0.666 1.886zm10.8-34.583-11.413 33.316 1.892 0.648 11.413-33.315-1.892-0.649zm12.866 0.363-11.832-1.035-0.175 1.993 11.833 1.035 0.174-1.993z" fill="#7F584A" mask="url(#h)"/><mask id="i" fill="white"><path d="m296.9 191.35 6.318 36.691-12.306-1.077-6.318-36.69 12.306 1.076z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m296.9 191.35 6.318 36.691-12.306-1.077-6.318-36.69 12.306 1.076z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m303.21 228.04-0.087 0.996 1.293 0.113-0.22-1.279-0.986 0.17zm-6.318-36.691 0.985-0.169-0.13-0.76-0.768-0.067-0.087 0.996zm-5.988 35.614-0.985 0.17 0.131 0.759 0.767 0.068 0.087-0.997zm-6.318-36.69 0.087-0.996-1.293-0.114 0.22 1.279 0.986-0.169zm19.61 37.597-6.319-36.69-1.971 0.339 6.319 36.691 1.971-0.34zm-13.379 0.09 12.306 1.076 0.175-1.992-12.307-1.077-0.174 1.993zm-7.217-37.518 6.319 36.691 1.971-0.339-6.319-36.691-1.971 0.339zm13.379-0.089-12.306-1.076-0.174 1.992 12.306 1.077 0.174-1.993z" fill="#7F584A" mask="url(#i)"/><rect transform="matrix(.42128 .90693 .91427 -.40512 387.24 280.8)" x=".66777" y=".25091" width="10.005" height="35.006" fill="#F5C8BA" stroke="#7F584A"/><mask id="j" fill="white"><path d="m419.83 266.52-35.895 9.333-2.088-3.848-1.766-7.062 34.084-8.863 5.665 10.44z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m419.83 266.52-35.895 9.333-2.088-3.848-1.766-7.062 34.084-8.863 5.665 10.44z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m383.94 275.86-0.879 0.477 0.373 0.688 0.758-0.197-0.252-0.968zm35.895-9.333 0.251 0.968 1.237-0.322-0.609-1.123-0.879 0.477zm-37.983 5.485-0.97 0.242 0.03 0.123 0.061 0.112 0.879-0.477zm-1.766-7.062-0.252-0.968-0.958 0.249 0.24 0.962 0.97-0.243zm34.084-8.863 0.879-0.477-0.374-0.687-0.757 0.197 0.252 0.967zm-29.978 20.741 35.894-9.333-0.503-1.936-35.894 9.334 0.503 1.935zm-3.219-4.339 2.088 3.848 1.758-0.954-2.088-3.848-1.758 0.954zm-1.857-7.296 1.766 7.061 1.94-0.485-1.766-7.062-1.94 0.486zm34.802-10.073-34.084 8.862 0.504 1.936 34.083-8.863-0.503-1.935zm6.796 10.93-5.665-10.44-1.758 0.954 5.665 10.44 1.758-0.954z" fill="#7F584A" mask="url(#j)"/><mask id="k" fill="white"><path d="m410.73 249.75-27.115 25.514-5.892-10.858 27.115-25.513 5.892 10.857z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m410.73 249.75-27.115 25.514-5.892-10.858 27.115-25.513 5.892 10.857z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m383.62 275.26-0.879 0.477 0.619 1.14 0.946-0.889-0.686-0.728zm27.115-25.514 0.685 0.728 0.561-0.528-0.368-0.677-0.878 0.477zm-33.007 14.656-0.685-0.728-0.561 0.528 0.367 0.677 0.879-0.477zm27.115-25.513 0.879-0.477-0.619-1.141-0.946 0.889 0.686 0.729zm-20.537 37.099 27.114-25.514-1.371-1.456-27.114 25.513 1.371 1.457zm-7.457-11.109 5.892 10.858 1.758-0.954-5.892-10.858-1.758 0.954zm27.308-26.719-27.114 25.514 1.371 1.456 27.114-25.513-1.371-1.457zm7.456 11.109-5.891-10.857-1.758 0.954 5.892 10.857 1.757-0.954z" fill="#7F584A" mask="url(#k)"/><rect transform="matrix(.88944 -.45704 .47276 .88119 229.54 203.32)" x=".6811" y=".21207" width="10.491" height="34.724" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.79657 .60455 .6186 -.78571 209.15 438.08)" x=".70758" y="-.090579" width="10.491" height="34.724" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(-.087156 .9962 .99463 .1035 401.84 332.1)" x=".45374" y=".54985" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><path d="m429.21 288.04-4.237-9.48-32.238 13.78 4.237 9.48 32.238-13.78z" fill="#F5C8BA" stroke="#7F584A"/><path d="m434.23 299.52-4.238-9.48-32.238 13.78 4.238 9.48 32.238-13.78z" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.56042 -.82821 .8373 .54675 182.02 243)" x=".69886" y="-.14073" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.56042 -.82821 .8373 .54675 168.14 263.87)" x=".69886" y="-.14073" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.56042 -.82821 .8373 .54675 188.95 232.57)" x=".69886" y="-.14073" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.56042 -.82821 .8373 .54675 175.08 253.44)" x=".69886" y="-.14073" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.40809 .91294 .91952 -.39305 164.21 375.54)" x=".6638" y=".25995" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><rect transform="matrix(.40809 .91294 .91952 -.39305 169.92 388.83)" x=".6638" y=".25995" width="10.384" height="35.059" fill="#F5C8BA" stroke="#7F584A"/><mask id="l" fill="white"><path d="m388.57 376.19 20.935 35.888-7.029 10.924-20.935-35.887 7.029-10.925z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m388.57 376.19 20.935 35.888-7.029 10.924-20.935-35.887 7.029-10.925z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m409.5 412.08 0.826 0.563 0.34-0.528-0.32-0.548-0.846 0.513zm-20.935-35.888 0.847-0.512-0.811-1.39-0.862 1.339 0.826 0.563zm13.906 46.812-0.847 0.513 0.811 1.39 0.862-1.34-0.826-0.563zm-20.935-35.887-0.826-0.563-0.34 0.527 0.32 0.548 0.846-0.512zm28.81 24.45-20.934-35.887-1.693 1.025 20.934 35.887 1.693-1.025zm-7.049 12 7.029-10.924-1.653-1.126-7.029 10.924 1.653 1.126zm-22.607-35.938 20.934 35.888 1.693-1.026-20.934-35.887-1.693 1.025zm7.049-12-7.029 10.925 1.653 1.126 7.029-10.925-1.653-1.126z" fill="#7F584A" mask="url(#l)"/><mask id="m" fill="white"><path d="m418.4 408.86 1e-3 -2e-3v2e-3h-1e-3zm2.005-11.427-6.859 10.66-41.931-6.624 6.859-10.66 41.931 6.624z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m418.4 408.86 1e-3 -2e-3v2e-3h-1e-3zm2.005-11.427-6.859 10.66-41.931-6.624 6.859-10.66 41.931 6.624z" clip-rule="evenodd" fill="#F5C8BA" fill-rule="evenodd"/><path d="m418.4 408.86 0.956 0.264-1.782-0.827 0.826 0.563zm-1e-3 2e-3 -0.827-0.563-0.849 1.32 1.535 0.243 0.141-1zm1e-3 0-0.142 1 0.876 0.139 0.222-0.875-0.956-0.264zm-4.855-0.767-0.141 1 0.623 0.099 0.345-0.536-0.827-0.563zm6.859-10.66 0.827 0.563 0.849-1.321-1.535-0.242-0.141 1zm-48.79 4.036-0.826-0.563-0.85 1.321 1.536 0.243 0.14-1.001zm6.859-10.66 0.141-1-0.622-0.098-0.345 0.535 0.826 0.563zm39.101 17.486-2e-3 2e-3 1.653 1.126 2e-3 -2e-3 -1.653-1.126zm1.782 0.829v-2e-3l-1.912-0.528-1e-3 2e-3 1.913 0.528zm-1.098 0.736 0.283-2h-1e-3l-0.282 2zm-3.886-1.204 6.859-10.66-1.653-1.126-6.859 10.66 1.653 1.126zm-42.898-6.186 41.93 6.623 0.282-2-41.931-6.624-0.281 2.001zm6.173-12.224-6.859 10.66 1.653 1.127 6.859-10.661-1.653-1.126zm42.898 6.187-41.931-6.624-0.281 2 41.93 6.624 0.282-2z" fill="#7F584A" mask="url(#m)"/><rect transform="rotate(185 216.79 354.49)" x="216.79" y="354.49" width="77" height="60" rx="30" fill="#F9F8F8" stroke="#5C5F60"/><mask id="n" fill="white"><path d="m246.8 426.54-14.545 23.292c12.047 9.583 30.493 16.596 51.598 18.442 19.912 1.742 38.292-1.455 51.667-7.992l-10.411-25.791c-10.804 3.608-24.257 5.156-38.642 3.897-15.507-1.357-29.383-5.737-39.667-11.848z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m246.8 426.54-14.545 23.292c12.047 9.583 30.493 16.596 51.598 18.442 19.912 1.742 38.292-1.455 51.667-7.992l-10.411-25.791c-10.804 3.608-24.257 5.156-38.642 3.897-15.507-1.357-29.383-5.737-39.667-11.848z" clip-rule="evenodd" fill="#F9F9F9" fill-rule="evenodd"/><path d="m232.26 449.83-0.848-0.53-0.473 0.757 0.698 0.556 0.623-0.783zm14.545-23.292 0.511-0.86-0.841-0.5-0.518 0.83 0.848 0.53zm88.72 33.742 0.439 0.898 0.837-0.409-0.348-0.863-0.928 0.374zm-10.411-25.791 0.927-0.375-0.352-0.872-0.892 0.298 0.317 0.949zm-92.006 15.871 14.545-23.292-1.696-1.06-14.545 23.292 1.696 1.06zm50.837 16.916c-20.955-1.833-39.202-8.793-51.063-18.229l-1.245 1.566c12.233 9.731 30.878 16.796 52.133 18.655l0.175-1.992zm51.141-7.894c-13.182 6.442-31.374 9.623-51.141 7.894l-0.175 1.992c20.057 1.755 38.626-1.458 52.194-8.09l-0.878-1.796zm-10.9-24.519 10.412 25.791 1.855-0.748-10.412-25.792-1.855 0.749zm-37.801 4.519c14.502 1.269 28.095-0.287 39.045-3.945l-0.633-1.897c-10.657 3.56-23.971 5.098-38.238 3.85l-0.174 1.992zm-40.091-11.984c10.433 6.199 24.459 10.617 40.091 11.984l0.174-1.992c-15.382-1.346-29.108-5.689-39.243-11.712l-1.022 1.72z" fill="#5C5F60" mask="url(#n)"/>';
        
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.DD) {
            return string(abi.encodePacked(
                partOne,
                flutedBezel,
                partTwo
            ));
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.DD_P) {
            return string(abi.encodePacked(
                partOne,
                smoothBezel,
                partTwo
            ));
        } else {
            revert IWatchScratchersWatchCaseRenderer.WrongCaseRendererCalled();
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchScratchersWatchCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}