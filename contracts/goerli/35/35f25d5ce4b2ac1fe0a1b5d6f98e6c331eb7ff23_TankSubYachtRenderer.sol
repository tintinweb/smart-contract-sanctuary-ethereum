//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";


contract TankSubYachtRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}

    function renderSubYacht(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) internal pure returns (string memory) {
        string memory maxiCase = '<rect transform="rotate(185 86.004 408.32)" x="86.004" y="408.32" width="46" height="166" fill="#B2B2B2"/><rect transform="rotate(185 329.99 671.58)" x="329.99" y="671.58" width="86" height="100" fill="#FCFCF9"/><rect transform="rotate(185 447.28 604.55)" x="447.28" y="604.55" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 447.28 604.55)" x="447.28" y="604.55" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 198.49 579.77)" x="198.49" y="579.77" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 198.49 579.77)" x="198.49" y="579.77" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 392.01 674)" x="392.01" y="674" width="51" height="110" fill="#B2B2B2"/><rect transform="rotate(185 224.74 658.36)" x="224.74" y="658.36" width="51" height="110" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 385.77 34.019)" width="86" height="100" fill="#FCFCF9"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 489.63 120.4)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 489.63 120.4)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 240.32 101.6)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 240.32 101.6)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 447.27 42.412)" width="51" height="110" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 279.82 28.766)" width="51" height="110" fill="#B2B2B2"/><rect transform="rotate(185 82.044 361.8)" x="82.044" y="361.8" width="43" height="68" fill="#FCFCF9"/><line x1="484.83" x2="439.68" y1="501.41" y2="615.91" stroke="#000" stroke-width="28"/><line x1="417.56" x2="390.53" y1="596.73" y2="687.72" stroke="#000" stroke-width="28"/><line x1="452.98" x2="403.87" y1="607.69" y2="606.74" stroke="#000" stroke-width="28"/><line transform="matrix(.19972 .97985 .97985 -.19972 136.09 466.91)" x2="123.08" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.11401 .99348 .99348 -.11401 185.98 573.66)" x2="94.921" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.98797 .15466 .15466 -.98797 137.45 566.06)" x2="49.114" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="404.7" x2="170.6" y1="678.12" y2="657.64" stroke="#000" stroke-width="28"/><line x1="334.96" x2="341.63" y1="661.21" y2="572.46" stroke="#000" stroke-width="38"/><line x1="240.27" x2="246.94" y1="652.93" y2="564.17" stroke="#000" stroke-width="38"/><line x1="319.23" x2="261.45" y1="622.46" y2="617.4" stroke="#000" stroke-width="28"/><line x1="412.88" x2="355.1" y1="607.56" y2="602.51" stroke="#000" stroke-width="28"/><line x1="228.67" x2="170.9" y1="590.44" y2="585.39" stroke="#000" stroke-width="28"/><line transform="matrix(-.19972 -.97985 -.97985 .19972 494.73 234.28)" x2="123.08" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.11401 -.99348 -.99348 .11401 444.84 127.52)" x2="94.921" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.98797 -.15466 -.15466 .98797 493.36 135.12)" x2="49.114" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="145.99" x2="191.14" y1="199.77" y2="85.27" stroke="#000" stroke-width="28"/><line x1="213.26" x2="240.29" y1="104.45" y2="13.46" stroke="#000" stroke-width="28"/><line x1="177.84" x2="226.95" y1="93.494" y2="94.44" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 459 57.492)" x2="235" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.09939 .99505 .99505 .09939 407.51 49.975)" x2="89.006" y1="-19" y2="-19" stroke="#000" stroke-width="38"/><line transform="matrix(-.09939 .99505 .99505 .09939 312.82 41.691)" x2="89.006" y1="-19" y2="-19" stroke="#000" stroke-width="38"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 365.16 97.465)" x2="58" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 454.8 128.4)" x2="58" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 270.42 113.27)" x2="58" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="110.62" x2="42.81" y1="443.47" y2="392.36" stroke="#000" stroke-width="28"/><line x1="48.162" x2="52.931" y1="404.86" y2="356.09" stroke="#000" stroke-width="28"/><line transform="matrix(-.89096 .45407 .45407 .89096 136.91 228.06)" x2="84.906" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.076987 .99703 .99703 .076987 76.303 243.84)" x2="49.007" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="80.223" x2="26.341" y1="362.64" y2="358.93" stroke="#000" stroke-width="28"/><line x1="86.498" x2="32.616" y1="290.91" y2="287.2" stroke="#000" stroke-width="28"/><line x1="32.832" x2="41.548" y1="373.55" y2="273.93" stroke="#000" stroke-width="28"/>';
        string memory diverDial = '<circle transform="rotate(185 368.22 464.13)" cx="368.22" cy="464.13" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 242.69 453.14)" cx="242.69" cy="453.14" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 261.61 236.97)" cx="261.61" cy="236.97" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 386.13 247.86)" cx="386.13" cy="247.86" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 418.05 422.31)" cx="418.05" cy="422.31" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 428.94 297.79)" cx="428.94" cy="297.79" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 200.88 403.31)" cx="200.88" cy="403.31" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 211.77 278.79)" cx="211.77" cy="278.79" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(185 454.27 369.77)" x="454.27" y="369.77" width="46" height="17" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(95 335.75 209.83)" x="335.75" y="209.83" width="46" height="17" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><path d="m323.18 489.3-15.642-48.679-23.858 45.224 39.5 3.455z" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(185 239.9 376.11)" x="239.9" y="376.11" width="87" height="65" rx="32.5" fill="#FCFDFD" stroke="#9EA09F"/>';
        string memory yachtBezel = '<circle transform="rotate(185 314.95 350.05)" cx="314.95" cy="350.05" r="226" fill="#BFBFBD" stroke="#000" stroke-width="28"/><path d="m141.25 333.35c8.375-95.725 92.988-166.53 189-158.13 96.014 8.4 167.05 92.821 158.67 188.55-8.375 95.725-92.988 166.53-189 158.13-96.014-8.401-167.05-92.822-158.67-188.55z" fill="#595958" stroke="#E0E0E0" stroke-width="5"/><path d="m298.36 528.28-27.437 25.455 50.038 4.378-22.601-29.833z" fill="#E2E2E0"/><rect transform="rotate(196.46 261.36 538.09)" x="261.36" y="538.09" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(204.26 241.88 531.37)" x="241.88" y="531.37" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(212.33 223.61 522.75)" x="223.61" y="522.75" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(221.83 189.36 499.67)" x="189.36" y="499.67" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(229.53 174.02 485.28)" x="174.02" y="485.28" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(233.54 161.56 470.14)" x="161.56" y="470.14" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(261.06 124.39 397.62)" x="124.39" y="397.62" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(267.88 120.83 377.23)" x="120.83" y="377.23" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(-88.235 119.4 358.04)" x="119.4" y="358.04" width="6.7035" height="15.135" fill="#FAFAFA"/><rect transform="rotate(216.95 201.79 521.84)" x="201.79" y="521.84" width="13" height="26" fill="#FAFAFA"/><rect transform="matrix(.89143 -.45315 -.45315 -.89143 396.78 538.9)" width="13" height="26" fill="#FAFAFA"/><rect transform="rotate(36.946 428.96 175.68)" x="428.96" y="175.68" width="13" height="26" fill="#FAFAFA"/><rect transform="matrix(-.89143 .45315 .45315 .89143 234.6 158.38)" width="13" height="26" fill="#FAFAFA"/><rect transform="rotate(95 136.08 329.38)" x="136.08" y="329.38" width="13" height="26" fill="#FAFAFA"/><rect transform="rotate(95 520.61 363.02)" x="520.61" y="363.02" width="13" height="26" fill="#FAFAFA"/>';
        string memory subBezel = '<circle transform="rotate(185 314.95 350.05)" cx="314.95" cy="350.05" r="237.5" fill="#0D4A29" stroke="#E0E0E0" stroke-width="5"/><path d="M141.246 333.347C149.621 237.622 234.234 166.818 330.249 175.218C426.263 183.618 497.296 268.039 488.921 363.765C480.546 459.49 395.933 530.294 299.918 521.894C203.904 513.493 132.871 429.072 141.246 333.347Z" fill="black" stroke="#E0E0E0" stroke-width="5"/><path d="m141.25 333.35c8.375-95.725 92.988-166.53 189-158.13 96.014 8.4 167.05 92.821 158.67 188.55-8.375 95.725-92.988 166.53-189 158.13-96.014-8.401-167.05-92.822-158.67-188.55z" stroke="#E0E0E0" stroke-width="5"/><path d="m299.09 531.36-32.536 34.043 58.666 5.133-26.13-39.176z" fill="#9E9E9E"/><rect transform="rotate(185.58 281.87 542)" x="281.87" y="542" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(196.46 261.36 538.09)" x="261.36" y="538.09" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(204.26 241.88 531.37)" x="241.88" y="531.37" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(212.33 223.61 522.75)" x="223.61" y="522.75" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(221.83 189.36 499.67)" x="189.36" y="499.67" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(229.53 174.02 485.28)" x="174.02" y="485.28" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(233.54 161.56 470.14)" x="161.56" y="470.14" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(237.52 150.25 454.09)" x="150.25" y="454.09" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(247.22 132 417.36)" x="132" y="417.36" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(261.06 124.39 397.62)" x="124.39" y="397.62" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(267.88 120.83 377.23)" x="120.83" y="377.23" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(-88.235 119.4 358.04)" x="119.4" y="358.04" width="6.7035" height="15.135" fill="#F5F5F5"/><circle transform="rotate(185 297.09 554.27)" cx="297.09" cy="554.27" r="13" fill="#D7D7D7"/><rect transform="rotate(216.95 189.24 539.12)" x="189.24" y="539.12" width="12.5" height="48.679" fill="#F5F5F5"/><rect transform="matrix(.89143 -.45315 -.45315 -.89143 406.59 557.83)" width="12.5" height="48.679" fill="#F5F5F5"/><rect transform="rotate(36.946 442.61 157.52)" x="442.61" y="157.52" width="12.5" height="48.679" fill="#F5F5F5"/><rect transform="matrix(-.89143 .45315 .45315 .89143 224.27 138.73)" width="12.5" height="48.679" fill="#F5F5F5"/><rect transform="rotate(95 136.5 329.86)" x="136.5" y="329.86" width="12.5" height="48.68" fill="#F5F5F5"/><rect transform="rotate(95 542.95 365.42)" x="542.95" y="365.42" width="12.5" height="48.68" fill="#F5F5F5"/>';
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.YACHT) {
            return string(abi.encodePacked(
                maxiCase,
                yachtBezel,
                diverDial
            ));
        } else {
            // SUB = YM but swap polished links + crown and bezel
            return string(abi.encodePacked(
                maxiCase,
                subBezel,
                diverDial
            ));
        }
    }

    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.TANK) {
            return '<rect transform="rotate(185 445.26 890.74)" x="445.26" y="890.74" width="292" height="186" fill="#0C0C0C"/><rect transform="rotate(185 506.55 224.55)" x="506.55" y="224.55" width="292" height="186" fill="#0C0C0C"/><rect transform="rotate(185 514.08 735.15)" x="514.08" y="735.15" width="43" height="516" fill="#F7E5B0"/><rect transform="rotate(185 161.17 707.28)" x="161.17" y="707.28" width="43" height="519" fill="#F7E5B0"/><rect transform="rotate(185 477.84 701.86)" x="477.84" y="701.86" width="337" height="36" fill="#F7E5B0"/><rect transform="rotate(185 524.98 266.31)" x="524.98" y="266.31" width="337" height="36" fill="#F7E5B0"/><circle transform="rotate(185 83.821 432.49)" cx="83.821" cy="432.49" r="32" fill="#1C55B4" stroke="#000" stroke-width="28"/><rect transform="rotate(185 129.45 484.67)" x="129.45" y="484.67" width="50" height="94" fill="#F7E5B0"/><line x1="131.95" x2="107.38" y1="466.61" y2="483.54" stroke="#000" stroke-width="28"/><line transform="matrix(-.71252 -.70165 -.70165 .71252 127.32 417.23)" x2="29.833" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="109.11" x2="78.074" y1="499.67" y2="452.79" stroke="#000" stroke-width="28"/><line transform="matrix(-.68836 .72537 .72537 .68836 130.54 380.37)" x2="56.223" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="87.656" x2="93.409" y1="468.97" y2="403.22" stroke="#000" stroke-width="14"/><rect transform="rotate(185 474.1 664.39)" x="474.1" y="664.39" width="308" height="394" fill="#F8F8F8" stroke="#000" stroke-width="28"/><path d="m331.63 581.66 16.728 44.628-12.146-1.063-16.727-44.627 12.145 1.062z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="352.01" x2="333.08" y1="625.6" y2="623.95" stroke="#010101" stroke-width="2"/><line x1="355.58" x2="346.62" y1="584.76" y2="583.98" stroke="#010101" stroke-width="2"/><line x1="352.41" x2="316.14" y1="584.1" y2="622.24" stroke="#010101" stroke-width="2"/><line x1="321.13" x2="281.28" y1="622.9" y2="619.42" stroke="#010101" stroke-width="2"/><line x1="335.66" x2="284.85" y1="583.02" y2="578.57" stroke="#010101" stroke-width="2"/><line x1="306.77" x2="310.17" y1="620.64" y2="581.79" stroke="#010101" stroke-width="11"/><line x1="289.84" x2="293.24" y1="619.16" y2="580.31" stroke="#010101" stroke-width="11"/><path d="m259.86 574.38-29.051 39.618-12.818-1.121 29.051-39.619 12.818 1.122zm-8.456-6.763-0.146-0.108-0.066 0.089 0.212 0.019z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="233.55" x2="214.62" y1="614.24" y2="612.58" stroke="#010101" stroke-width="2"/><line x1="262.03" x2="243.1" y1="575.57" y2="573.92" stroke="#010101" stroke-width="2"/><path d="m194.51 532.72 0.211 0.485 42.523-18.509 1.091-12.472-42.786 18.624-1.039 11.872z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m192.91 550.99 0.212 0.485 42.522-18.51 1.091-12.472-42.786 18.625-1.039 11.872z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="193.52" x2="196.92" y1="555.52" y2="516.67" stroke="#010101" stroke-width="2"/><line x1="235.28" x2="238.68" y1="537.09" y2="498.24" stroke="#010101" stroke-width="2"/><line x1="242.42" x2="201.58" y1="466.95" y2="463.38" stroke="#010101" stroke-width="11"/><line x1="243.82" x2="202.97" y1="451.01" y2="447.44" stroke="#010101" stroke-width="11"/><line x1="245.3" x2="204.45" y1="434.08" y2="430.5" stroke="#010101" stroke-width="11"/><line x1="241.59" x2="246.04" y1="476.41" y2="425.61" stroke="#010101" stroke-width="2"/><line x1="201.75" x2="206.19" y1="472.93" y2="422.12" stroke="#010101" stroke-width="2"/><path d="m210.55 372.31 37.802 26.875-1.112 12.707-37.801-26.876 1.111-12.706z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m212.14 354.15 37.802 26.875-1.112 12.707-37.801-26.876 1.111-12.706z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m213.71 336.22 37.802 26.876-1.112 12.706-37.802-26.875 1.112-12.707z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m216.18 319.37 37.802 26.875-1.112 12.706-37.801-26.875 1.111-12.706z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="246.91" x2="254.36" y1="415.63" y2="342" stroke="#010101" stroke-width="2"/><line x1="209.16" x2="216.6" y1="388.24" y2="314.6" stroke="#010101" stroke-width="2"/><path d="m256.14 287.26 24.516 29.542-1.381 15.559-38.548-46.449 15.413 1.348z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="280.26" x2="282.05" y1="332.58" y2="289.57" stroke="#010101" stroke-width="2"/><line x1="285.02" x2="277.06" y1="289.78" y2="289.09" stroke="#010101" stroke-width="2"/><line x1="261.12" x2="238.2" y1="287.69" y2="285.69" stroke="#010101" stroke-width="2"/><path d="m400.78 332.07 2.731-31.212-10.958-0.958-3.835 43.833 12.062-11.663z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="407.41" x2="389.48" y1="302.2" y2="300.63" stroke="#010101" stroke-width="2"/><line x1="392.77" x2="405.54" y1="338.4" y2="326.46" stroke="#010101" stroke-width="2"/><path d="m447.29 305.69-28.068 38.701-10.991-0.961-1.245-0.904 27.526-37.954 12.778 1.118z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m466.18 307.34-28.068 38.7-10.991-0.961-1.245-0.903 27.527-37.954 12.777 1.118z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="469.17" x2="428.33" y1="307.6" y2="304.03" stroke="#010101" stroke-width="2"/><line x1="469.17" x2="428.33" y1="307.6" y2="304.03" stroke="#010101" stroke-width="2"/><line x1="440.69" x2="402.84" y1="346.27" y2="342.96" stroke="#010101" stroke-width="2"/><line x1="440.69" x2="402.84" y1="346.27" y2="342.96" stroke="#010101" stroke-width="2"/><path d="m405.67 323.91 2.816-2.964-1.712-1.627 17.47-17.9 3.578 3.493-20.304 20.803-1.848-1.805z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m485.2 342.46-25.272 20.737-18.776 1.177 45.389-37.244-1.341 15.33z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="483.88" x2="486.06" y1="346.03" y2="321.13" stroke="#010101" stroke-width="2"/><path d="m482.2 376.69-42.896 19.89 1.105-12.638 42.897-19.89-1.106 12.638z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m480.65 394.38-42.896 19.89 1.105-12.637 42.897-19.89-1.106 12.637z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m479.08 412.32-42.897 19.89 1.106-12.638 42.896-19.89-1.105 12.638z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="435.93" x2="440.81" y1="435.19" y2="379.41" stroke="#010101" stroke-width="2"/><line x1="477.69" x2="483.09" y1="416.76" y2="355" stroke="#010101" stroke-width="2"/><line x1="447.13" x2="482.43" y1="362.9" y2="360.97" stroke="#010101" stroke-width="2"/><line x1="473.25" x2="433.4" y1="456.02" y2="452.54" stroke="#010101" stroke-width="11"/><path d="m429.72 494.66 42.668-17.265 1.076-12.302-42.667 17.265-1.077 12.302z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="471.03" x2="473.99" y1="481.43" y2="447.56" stroke="#010101" stroke-width="2"/><line x1="432.14" x2="434.14" y1="466.98" y2="444.07" stroke="#010101" stroke-width="2"/><line x1="469.29" x2="469.98" y1="501.35" y2="493.38" stroke="#010101" stroke-width="2"/><line x1="429.44" x2="431.1" y1="497.87" y2="478.94" stroke="#010101" stroke-width="2"/><line x1="469.94" x2="432.88" y1="498.18" y2="462.81" stroke="#010101" stroke-width="2"/><path d="m423.41 555.33 41.067 1.021 0.961-10.98-41.067-1.021-0.961 10.98z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="463.24" x2="464.72" y1="559.04" y2="542.11" stroke="#010101" stroke-width="2"/><line x1="423.13" x2="424.61" y1="558.55" y2="541.61" stroke="#010101" stroke-width="2"/><line x1="460.88" x2="461.84" y1="585.94" y2="574.98" stroke="#010101" stroke-width="2"/><line x1="426.09" x2="426.96" y1="524.68" y2="514.71" stroke="#010101" stroke-width="2"/><line x1="461.44" x2="426.73" y1="581.53" y2="519.27" stroke="#010101" stroke-width="2"/><path d="m403.31 589.94 37.271 44.417-15.497-1.355-37.271-44.418 15.497 1.356z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m381.42 587.02 20.895 43.989-12.706-1.112-20.894-43.988 12.705 1.111z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="445.57" x2="420.66" y1="634.79" y2="632.61" stroke="#010101" stroke-width="2"/><line x1="409.7" x2="384.8" y1="631.66" y2="629.48" stroke="#010101" stroke-width="2"/><line x1="407.39" x2="365.55" y1="589.29" y2="585.63" stroke="#010101" stroke-width="2"/><line x1="426.31" x2="418.34" y1="590.95" y2="590.25" stroke="#010101" stroke-width="2"/><line x1="405.79" x2="422.4" y1="631.02" y2="590.31" stroke="#010101" stroke-width="2"/><rect transform="rotate(185 411.14 575.06)" x="411.14" y="575.06" width="165" height="218" stroke="#070707"/><rect transform="rotate(185 400.06 564.06)" x="400.06" y="564.06" width="141" height="197" stroke="#070707"/><line x1="353.19" x2="356.9" y1="338.62" y2="296.14" stroke="#000" stroke-width="11"/><line x1="363.01" x2="343.56" y1="339.22" y2="337.52" stroke="#000" stroke-width="2"/><line x1="365.59" x2="345.06" y1="297.27" y2="295.48" stroke="#000" stroke-width="2"/><line x1="336.44" x2="315.91" y1="294.28" y2="292.49" stroke="#000" stroke-width="2"/><path d="m339 322-6.432-28.626-11.376-0.995 10.234 45.551 7.574-15.93z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="337.34" x2="350.79" y1="323.14" y2="296.17" stroke="#000" stroke-width="2"/><path d="m533.59 695.7c-3.017 34.489-29.88 61.163-62.922 65.199l2.533-28.947c17.385-4.636 30.837-19.732 32.495-38.692l38.175-436.33c1.659-18.96-8.967-36.162-25.284-43.747l2.533-28.947c31.839 9.713 53.662 40.646 50.644 75.135l-38.174 436.33zm-329.28-538.96c-32.576 4.453-58.92 30.933-61.907 65.068l-38.174 436.33c-2.986 34.135 18.36 64.787 49.667 74.829l2.546-29.104c-15.769-7.805-25.945-24.7-24.32-43.285l38.175-436.33c1.626-18.585 14.582-33.456 31.467-38.404l2.546-29.104z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="464.68" x2="471.83" y1="771.98" y2="690.29" stroke="#000" stroke-width="28"/><line x1="157.85" x2="165.09" y1="745.14" y2="662.45" stroke="#000" stroke-width="28"/><line x1="473.55" x2="170.8" y1="704.5" y2="676.99" stroke="#000" stroke-width="28"/><line x1="465.02" x2="437.67" y1="769.32" y2="897.12" stroke="#000" stroke-width="28"/><line transform="matrix(.036281 .99934 .99934 -.036281 172.29 741.97)" x2="130.7" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="452.67" x2="150.82" y1="886.37" y2="859.96" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 531.77 165.8)" x2="82" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 224.94 138.96)" x2="83" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.99648 -.083835 -.083835 .99648 513.66 246.53)" x2="304" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.036281 -.99934 -.99934 .036281 503.7 167.77)" x2="130.7" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="210.97" x2="238.32" y1="140.43" y2="12.623" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 524.63 63.793)" x2="303" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        } else if (
            caseType == IWatchScratchersWatchCaseRenderer.CaseType.YACHT || 
            caseType == IWatchScratchersWatchCaseRenderer.CaseType.SUB
        ) {
            return renderSubYacht(caseType);
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