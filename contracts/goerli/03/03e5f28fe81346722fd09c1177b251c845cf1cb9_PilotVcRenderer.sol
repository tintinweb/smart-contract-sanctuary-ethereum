//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";


contract PilotVcRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}

    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        string memory pilotDial = '<path d="m413.6 495.51c7.571 0.662 9.987-5.15 10.248-8.138l1.613-18.43c0.13-1.495 0.242-8.512-8.724-9.296-7.172-0.627-9.459 4.861-9.706 7.683l-1.656 18.928c-0.628 7.173 5.222 9.157 8.225 9.253z" stroke="#fff" stroke-width="8"/><path d="m294.43 555.35-15.437-32.218 36.234 3.171-20.797 29.047z" fill="#fff"/><circle transform="rotate(185 313.25 552.48)" cx="313.25" cy="552.48" r="5.5" fill="#fff"/><circle transform="rotate(185 276.39 549.25)" cx="276.39" cy="549.25" r="5.5" fill="#fff"/><rect transform="rotate(185 205.45 402.01)" x="205.45" y="402.01" width="40" height="33" fill="#001D47"/><rect transform="rotate(185 201.82 397.68)" x="201.82" y="397.68" width="32" height="24" fill="#F9FEFF"/><path d="m256.75 286.04-20.422-1.787m16.132 4.925 3.468-22.785m0.075-0.495-0.075 0.495m0.965-4.934c0.305-3.487-0.18-10.556-6.556-11.114-2.96-0.594-9.07 0.411-9.837 9.177-0.305 3.487 0.678 10.6 7.054 11.158 2.289 0.367 7.168 0.025 8.374-4.287" stroke="#fff" stroke-width="8"/><path d="m311.89 258.24c-0.392 4.483 0.722 10.101 7.098 10.659 2.657 0.233 8.127-1.096 8.754-8.268 0.628-7.173 1.307-14.943 1.569-17.932m0 0c0.066-2.671-1.196-8.135-6.774-8.623-2.808-0.413-8.59 0.654-9.252 8.225-0.428 2.974-0.304 9.208 3.611 10.354 3.868 1.677 11.767 2.033 12.415-9.956z" stroke="#fff" stroke-width="8"/><path d="m430.78 344.93c-0.523 5.977 4.327 7.907 6.818 8.125 5.977 0.523 7.907-4.327 8.125-6.817 0.558-6.376-4.284-8.406-6.774-8.624-5.977-0.523-7.937 4.66-8.169 7.316z" stroke="#fff" stroke-width="8"/><path d="m445.78 414.5c0.732-8.368 6.56-9.966 9.383-9.72 0.996 0.088 7.97 0.698 7.054 11.158-0.732 8.368-6.228 9.995-8.884 9.763-6.774-0.593-7.858-7.715-7.553-11.201zl1.569-17.932c0.369-2.31 2.802-6.781 9.576-6.189 2.656 0.233 7.804 2.59 7.141 10.161" stroke="#fff" stroke-width="8"/><path d="m224.27 531.14 3.704-42.339" stroke="#fff" stroke-width="8"/><path d="m361.74 543.17 3.704-42.338" stroke="#fff" stroke-width="8"/><path d="m434.75 500.37 3.705-42.338" stroke="#fff" stroke-width="8"/><path d="m185.52 463.5c-0.348 3.985-1.002 11.456-8.473 10.802-4.483-0.392-11.802-3.943-5.212-15.011l16.101-17.664m3.305-1.217-23.596-2.064" stroke="#fff" stroke-width="8"/><path d="m374.69 544.3 3.704-42.338" stroke="#fff" stroke-width="8"/><path d="m184.32 333.69 3.642-41.626m16.518 11.986-25.403-2.223m21.742 3.91-15.845 26.219" stroke="#fff" stroke-width="8"/><path d="m403.54 294.86-15.939-1.394 0.071-0.812 14.56-32.038-8.451-0.739-13.675 30.091-0.284 0.624-0.06 0.682-0.479 5.479 0.175 0.016-0.349 3.985 3.81 0.333 19.924 1.743 0.697-7.97z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m447.79 328.35c-0.662 7.571-6.502 9.302-9.339 9.221-1.992-0.175-7.839-2.192-7.054-11.158 0.784-8.965 7.347-9.395 8.841-9.264 1.494 0.13 8.38 1.737 7.552 11.201z" stroke="#fff" stroke-width="8"/>';
        string memory senatorDial = '<line x1="310.78" x2="303.77" y1="570.07" y2="569.45" stroke="#000" stroke-width="2"/><line x1="314" x2="307.86" y1="533.28" y2="532.74" stroke="#000" stroke-width="2"/><line x1="304.36" x2="284.21" y1="532.43" y2="530.67" stroke="#000" stroke-width="2"/><line x1="300.26" x2="280.99" y1="569.15" y2="567.46" stroke="#000" stroke-width="2"/><line x1="310.57" x2="297.71" y1="533.11" y2="569.06" stroke="#000" stroke-width="2"/><line x1="291.2" x2="294.57" y1="569.12" y2="530.57" stroke="#000" stroke-width="4"/><line x1="284.19" x2="287.56" y1="568.5" y2="529.96" stroke="#000" stroke-width="4"/><line x1="307.06" x2="300.65" y1="570.13" y2="532.49" stroke="#000" stroke-width="4"/><line x1="485.98" x2="485.37" y1="405.2" y2="412.2" stroke="#000" stroke-width="2"/><line x1="449.19" x2="448.65" y1="401.98" y2="408.11" stroke="#000" stroke-width="2"/><line x1="448.34" x2="447.73" y1="411.61" y2="418.62" stroke="#000" stroke-width="2"/><line x1="485.06" x2="484.6" y1="415.71" y2="420.96" stroke="#000" stroke-width="2"/><line x1="449.02" x2="484.97" y1="405.4" y2="418.26" stroke="#000" stroke-width="2"/><line x1="487.02" x2="448.48" y1="402" y2="398.63" stroke="#000" stroke-width="4"/><line x1="486.05" x2="448.41" y1="408.91" y2="415.33" stroke="#000" stroke-width="4"/><line x1="486.6" x2="485.98" y1="398.19" y2="405.2" stroke="#000" stroke-width="2"/><line x1="449.8" x2="449.19" y1="394.97" y2="401.98" stroke="#000" stroke-width="2"/><line x1="458.4" x2="454.26" y1="488.22" y2="493.91" stroke="#000" stroke-width="2"/><line x1="428.51" x2="424.9" y1="466.51" y2="471.49" stroke="#000" stroke-width="2"/><line x1="422.83" x2="418.7" y1="474.34" y2="480.03" stroke="#000" stroke-width="2"/><line x1="452.2" x2="449.1" y1="496.76" y2="501.03" stroke="#000" stroke-width="2"/><line x1="426.61" x2="450.81" y1="469.36" y2="498.9" stroke="#000" stroke-width="2"/><line x1="456.54" x2="420.97" y1="491.43" y2="477.56" stroke="#000" stroke-width="4"/><line x1="395.43" x2="389.08" y1="546.49" y2="549.52" stroke="#000" stroke-width="2"/><line x1="379.48" x2="373.93" y1="513.17" y2="515.83" stroke="#000" stroke-width="2"/><line x1="370.76" x2="358.86" y1="517.35" y2="523.04" stroke="#000" stroke-width="2"/><line x1="385.91" x2="374.81" y1="551.04" y2="556.36" stroke="#000" stroke-width="2"/><line x1="376.45" x2="383.67" y1="514.77" y2="552.26" stroke="#000" stroke-width="2"/><line x1="378.09" x2="361.38" y1="555.63" y2="520.73" stroke="#000" stroke-width="4"/><line x1="392.27" x2="367.6" y1="548.43" y2="519.29" stroke="#000" stroke-width="4"/><line x1="234.33" x2="229.33" y1="509.74" y2="506.14" stroke="#000" stroke-width="2"/><line x1="212.25" x2="207.25" y1="540.12" y2="536.53" stroke="#000" stroke-width="2"/><line x1="209.35" x2="231.92" y1="538.47" y2="507.04" stroke="#000" stroke-width="4"/><line x1="188.87" x2="183" y1="460.22" y2="447.43" stroke="#000" stroke-width="2"/><line x1="155.3" x2="149.43" y1="475.63" y2="462.84" stroke="#000" stroke-width="2"/><line x1="153.04" x2="188.21" y1="472.53" y2="456.39" stroke="#000" stroke-width="4"/><line x1="150.11" x2="185.27" y1="466.13" y2="449.99" stroke="#000" stroke-width="4"/><line x1="171.53" x2="173.37" y1="394.4" y2="373.38" stroke="#000" stroke-width="2"/><line x1="134.73" x2="136.57" y1="391.24" y2="370.21" stroke="#000" stroke-width="2"/><line x1="134.92" x2="173.46" y1="380.39" y2="383.76" stroke="#000" stroke-width="4"/><line x1="134.31" x2="172.86" y1="387.4" y2="390.77" stroke="#000" stroke-width="4"/><line x1="135.54" x2="174.09" y1="373.41" y2="376.78" stroke="#000" stroke-width="4"/><line x1="189.14" x2="205.15" y1="327.47" y2="304.4" stroke="#000" stroke-width="2"/><line x1="158.75" x2="174.79" y1="306.48" y2="283.36" stroke="#000" stroke-width="2"/><line x1="164.29" x2="196.09" y1="297.15" y2="319.19" stroke="#000" stroke-width="4"/><line x1="160.29" x2="192.09" y1="302.94" y2="324.98" stroke="#000" stroke-width="4"/><line x1="168.29" x2="200.09" y1="291.4" y2="313.44" stroke="#000" stroke-width="4"/><line x1="172.3" x2="204.1" y1="285.62" y2="307.66" stroke="#000" stroke-width="4"/><line x1="249.7" x2="240.13" y1="271.87" y2="234.62" stroke="#000" stroke-width="2"/><line x1="233.18" x2="226.8" y1="238.18" y2="241.15" stroke="#000" stroke-width="2"/><line x1="242.75" x2="237.96" y1="233.74" y2="235.96" stroke="#000" stroke-width="2"/><path d="m245.09 258.91-13.021-19.992-3.352 2.183 19.482 29.912-3.109-12.103z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="250.51" x2="248.92" y1="271.28" y2="272.02" stroke="#000"/><line x1="317.6" x2="327.91" y1="258.75" y2="221.69" stroke="#000" stroke-width="2"/><line x1="320.1" x2="313.09" y1="221.31" y2="220.7" stroke="#000" stroke-width="2"/><line x1="337.62" x2="325.36" y1="222.85" y2="221.77" stroke="#000" stroke-width="2"/><line x1="334.4" x2="327.4" y1="259.64" y2="259.03" stroke="#000" stroke-width="2"/><path d="m320.08 245.21-1.303-23.823-3.994 0.218 1.949 35.644 3.348-12.039z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="318.6" x2="316.85" y1="258.64" y2="258.48" stroke="#000"/><line x1="330.75" x2="333.89" y1="258.32" y2="222.4" stroke="#000" stroke-width="4"/><line x1="382.64" x2="410.16" y1="278.93" y2="252.06" stroke="#000" stroke-width="2"/><line x1="403.6" x2="397.85" y1="247.82" y2="243.76" stroke="#000" stroke-width="2"/><line x1="412.23" x2="407.92" y1="253.89" y2="250.85" stroke="#000" stroke-width="2"/><path d="m391.57 268.47 10.842-21.252-3.563-1.817-16.222 31.797 8.943-8.728z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="383.55" x2="382.12" y1="279.33" y2="278.32" stroke="#000"/><line x1="423.73" x2="412.23" y1="261.99" y2="253.89" stroke="#000" stroke-width="2"/><line x1="402.45" x2="390.95" y1="292.18" y2="284.08" stroke="#000" stroke-width="2"/><line x1="398.95" x2="421.23" y1="290.64" y2="259.01" stroke="#000" stroke-width="4"/><line x1="393.2" x2="415.48" y1="286.59" y2="254.95" stroke="#000" stroke-width="4"/><line x1="435.16" x2="444.39" y1="335.27" y2="354.25" stroke="#000" stroke-width="2"/><line x1="466.04" x2="477.59" y1="314.38" y2="338.07" stroke="#000" stroke-width="2"/><line x1="473.77" x2="438.97" y1="328.48" y2="345.4" stroke="#000" stroke-width="4"/><line x1="470.68" x2="435.89" y1="322.15" y2="339.08" stroke="#000" stroke-width="4"/><line x1="476.82" x2="442.02" y1="334.79" y2="351.72" stroke="#000" stroke-width="4"/><line x1="430.13" x2="467.21" y1="326.85" y2="316.63" stroke="#000" stroke-width="2"/><line x1="463.52" x2="460.44" y1="309.74" y2="303.42" stroke="#000" stroke-width="2"/><path d="m443.01 322.01 19.761-13.366-2.241-3.313-29.567 19.998 12.047-3.319z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="430.73" x2="429.96" y1="327.64" y2="326.06" stroke="#000"/><rect transform="rotate(185 262.38 344.9)" x="262.38" y="344.9" width="71.869" height="52.523" fill="#EDECE6" stroke="#D5D4D0" stroke-width="2"/><rect transform="rotate(185 253.74 332.67)" x="253.74" y="332.67" width="50.764" height="30.538" fill="#F7F7F7" stroke="#9A928C" stroke-width="2"/>';
        string memory simpleCase = '<rect transform="rotate(185 389.07 764.39)" x="389.07" y="764.39" width="217" height="90" fill="#472A1B"/><rect transform="rotate(185 438.17 134.27)" x="438.17" y="134.27" width="217" height="87" fill="#472A1B"/><rect transform="rotate(185 437.83 700.4)" x="437.83" y="700.4" width="34" height="92" fill="#D3D3D3"/><rect transform="rotate(185 164.96 675.52)" x="164.96" y="675.52" width="34" height="92" fill="#D3D3D3"/><rect transform="rotate(185 480.54 212.26)" x="480.54" y="212.26" width="34" height="92" fill="#D3D3D3"/><rect transform="rotate(185 207.67 187.38)" x="207.67" y="187.38" width="34" height="92" fill="#D3D3D3"/><rect transform="rotate(185 71.327 403.32)" x="71.327" y="403.32" width="41" height="68" fill="#D3D3D3"/><line x1="68.6" x2="30.744" y1="400.07" y2="396.76" stroke="#000" stroke-width="28"/><line x1="74.09" x2="36.235" y1="337.31" y2="334" stroke="#000" stroke-width="28"/><line x1="28.528" x2="36.459" y1="410.62" y2="319.97" stroke="#000" stroke-width="28"/><circle transform="rotate(185 310.95 395.18)" cx="310.95" cy="395.18" r="238" fill="#D3D3D3" stroke="#000" stroke-width="28"/><circle transform="rotate(185 310.95 395.18)" cx="310.95" cy="395.18" r="196" fill="#15355C" stroke="#000" stroke-width="28"/><line x1="472.96" x2="428.67" y1="569.38" y2="697" stroke="#000" stroke-width="28"/><line x1="435.95" x2="397.18" y1="689.22" y2="707.92" stroke="#000" stroke-width="28"/><line x1="388.11" x2="402.05" y1="775.35" y2="615.96" stroke="#000" stroke-width="28"/><line transform="matrix(.15883 .98731 .98731 -.15883 134.06 535.29)" x2="135.09" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.81172 .58404 .58404 -.81172 144.05 650.6)" x2="43.046" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.076204 -.99709 -.99709 -.076204 156 755.04)" x2="160" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="398.17" x2="167.04" y1="671.83" y2="651.61" stroke="#000" stroke-width="28"/><line x1="399.29" x2="157.22" y1="762.27" y2="741.09" stroke="#000" stroke-width="28"/><line transform="matrix(-.15883 -.98731 -.98731 .15883 486.92 253.98)" x2="135.09" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.81172 -.58404 -.58404 .81172 476.94 138.67)" x2="43.046" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 466.9 35.399)" x2="160" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="147.86" x2="192.15" y1="221.88" y2="94.258" stroke="#000" stroke-width="28"/><line x1="184.86" x2="223.64" y1="102.04" y2="83.348" stroke="#000" stroke-width="28"/><line x1="234.77" x2="219.08" y1="15.245" y2="174.47" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 443.66 151.82)" x2="232.01" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 460.47 62.944)" x2="243" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.PILOT) {
            return string(abi.encodePacked(
                simpleCase,
                pilotDial
            ));
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.SENATOR) {
            return string(abi.encodePacked(
                simpleCase,
                senatorDial
            ));
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.VC) {
            return '<rect transform="rotate(185 68.211 356.99)" x="68.211" y="356.99" width="42" height="61" fill="#B6B6B6"/><rect transform="rotate(185 398.19 669.94)" x="398.19" y="669.94" width="255" height="93" fill="#B6B6B6"/><rect transform="rotate(125 457.22 557.45)" x="457.22" y="557.45" width="88" height="48" fill="#B6B6B6"/><rect transform="matrix(.42262 .90631 .90631 -.42262 104 526.54)" width="88" height="48" fill="#B6B6B6"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 452.92 44.33)" width="255" height="97" fill="#B6B6B6"/><rect transform="matrix(-.42262 -.90631 -.90631 .42262 491.19 169.14)" width="88" height="48" fill="#B6B6B6"/><rect transform="rotate(-55 137.97 138.24)" x="137.97" y="138.24" width="88" height="48" fill="#B6B6B6"/><circle transform="rotate(185 297.96 346.98)" cx="297.96" cy="346.98" r="231" fill="#EAEAEA" stroke="#000" stroke-width="28"/><circle transform="rotate(185 297.5 346.43)" cx="297.5" cy="346.43" r="182.5" fill="#01308C" stroke="#EAEAEA" stroke-width="28"/><path d="m225.76 529.69-1.656 18.927c14.799 5.512 33.368 9.632 53.709 11.411 22.163 1.939 42.736 0.778 58.963-2.727l1.655-18.927c-16.226 3.504-36.799 4.666-58.962 2.727-20.341-1.78-38.91-5.9-53.709-11.411z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><path d="m258.74 152.65 1.656-18.927c15.532-2.859 34.534-3.691 54.876-1.911 22.163 1.939 42.221 6.655 57.593 12.924l-1.656 18.928c-15.372-6.269-35.43-10.986-57.593-12.925-20.342-1.779-39.344-0.947-54.876 1.911z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><path d="m102.33 376.04-17.118 8.243c2.8192 15.539 8.7607 33.607 17.62 52.005 9.651 20.045 21.157 37.139 32.456 49.3l17.119-8.243c-11.299-12.161-22.805-29.255-32.456-49.3-8.859-18.398-14.8-36.466-17.62-52.005z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><path d="m485.12 405.97 15.761 10.61c-5.016 14.974-13.484 32.005-24.887 48.944-12.423 18.456-26.259 33.726-39.184 44.143l-15.762-10.61c12.926-10.417 26.761-25.687 39.185-44.143 11.402-16.939 19.871-33.97 24.887-48.944z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><path d="m110.42 284.41-15.64-10.787c5.1848-14.917 13.844-31.852 25.438-48.661 12.631-18.314 26.637-33.427 39.68-43.697l15.64 10.787c-13.042 10.27-27.049 25.383-39.68 43.697-11.593 16.809-20.253 33.744-25.438 48.661z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><path d="m493.44 317.92 17.276-7.908c-2.516-15.591-8.104-33.771-16.602-52.338-9.259-20.23-20.428-37.545-31.489-49.924l-17.276 7.907c11.06 12.379 22.23 29.695 31.489 49.924 8.498 18.567 14.086 36.748 16.602 52.339z" clip-rule="evenodd" fill="#B6B6B6" fill-rule="evenodd"/><circle transform="rotate(185 297.96 346.98)" cx="297.96" cy="346.98" r="215" stroke="#B6B6B6" stroke-width="4"/><rect transform="rotate(154.67 365.1 483.35)" x="365.1" y="483.35" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="matrix(-.8158 -.57833 -.57833 .8158 386.01 225.72)" x="-2.0912" y=".3562" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="rotate(126.25 422.94 432.25)" x="422.94" y="432.25" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="matrix(-.44223 -.8969 -.8969 .44223 434.07 286.43)" x="-2.0087" y="-.68202" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="matrix(.44223 .8969 .8969 -.44223 159.38 408.83)" x="2.0087" y=".68202" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="rotate(-53.754 172.51 265.92)" x="172.51" y="265.92" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="matrix(.8158 .57833 .57833 -.8158 207.07 469.16)" x="2.0912" y="-.3562" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><rect transform="rotate(-25.333 230.98 214.52)" x="230.98" y="214.52" width="8.0519" height="47.714" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="3"/><mask id="c" fill="white"><path d="m450.13 351.61-1.864 21.301-50.427-8.778 1.067-12.197 51.224-0.326z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m450.13 351.61-1.864 21.301-50.427-8.778 1.067-12.197 51.224-0.326z" clip-rule="evenodd" fill="#FFFCFB" fill-rule="evenodd"/><path d="m448.27 372.91-0.514 2.956 3.218 0.56 0.285-3.254-2.989-0.262zm1.864-21.301 2.988 0.262 0.287-3.283-3.294 0.021 0.019 3zm-52.291 12.523-2.988-0.261-0.241 2.744 2.715 0.473 0.514-2.956zm1.067-12.197-0.019-3-2.731 0.018-0.238 2.721 2.988 0.261zm52.349 21.237 1.863-21.301-5.977-0.523-1.864 21.301 5.978 0.523zm-53.93-6.084 50.427 8.778 1.029-5.911-50.427-8.779-1.029 5.912zm-1.407-15.414-1.067 12.197 5.977 0.522 1.067-12.196-5.977-0.523zm54.193-3.065-51.224 0.326 0.038 6 51.224-0.326-0.038-6z" fill="#C9C5C8" mask="url(#c)"/><mask id="b" fill="white"><path d="m300.69 196.64 21.301 1.864-8.778 50.427-12.197-1.067-0.326-51.224z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m300.69 196.64 21.301 1.864-8.778 50.427-12.197-1.067-0.326-51.224z" clip-rule="evenodd" fill="#FFFCFB" fill-rule="evenodd"/><path d="m321.99 198.51 2.956 0.514 0.56-3.218-3.254-0.285-0.262 2.989zm-21.301-1.864 0.262-2.988-3.283-0.287 0.021 3.294 3-0.019zm12.523 52.291-0.261 2.988 2.744 0.24 0.473-2.714-2.956-0.514zm-12.197-1.067-3 0.019 0.018 2.731 2.721 0.238 0.261-2.988zm21.237-52.349-21.301-1.863-0.523 5.977 21.301 1.863 0.523-5.977zm-6.084 53.93 8.778-50.427-5.911-1.029-8.778 50.427 5.911 1.029zm-15.414 1.407 12.197 1.067 0.523-5.977-12.197-1.067-0.523 5.977zm-3.065-54.193 0.326 51.224 6-0.038-0.326-51.224-6 0.038z" fill="#C9C5C8" mask="url(#b)"/><mask id="a" fill="white"><path d="m274.19 499.48 21.301 1.864 0.112-51.185-12.197-1.067-9.216 50.388z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m274.19 499.48 21.301 1.864 0.112-51.185-12.197-1.067-9.216 50.388z" clip-rule="evenodd" fill="#FFFCFB" fill-rule="evenodd"/><path d="m295.49 501.35 3 6e-3 -7e-3 3.267-3.254-0.285 0.261-2.988zm-21.301-1.864-0.261 2.989-3.283-0.288 0.593-3.241 2.951 0.54zm21.413-49.321 0.261-2.989 2.745 0.24-6e-3 2.755-3-6e-3zm-12.197-1.067-2.951-0.54 0.492-2.687 2.721 0.238-0.262 2.989zm11.824 55.24-21.301-1.863 0.523-5.978 21.301 1.864-0.523 5.977zm3.373-54.167-0.112 51.185-6-0.013 0.112-51.185 6 0.013zm-14.935-4.062 12.196 1.067-0.523 5.977-12.196-1.067 0.523-5.977zm-12.429 52.837 9.216-50.388 5.902 1.079-9.216 50.389-5.902-1.08z" fill="#C9C5C8" mask="url(#a)"/><rect transform="rotate(185 190.34 355.13)" x="190.34" y="355.13" width="40" height="29" fill="#FFFCFB" stroke="#C9C5C8" stroke-width="5"/><line x1="500.19" x2="405.54" y1="459.46" y2="642.79" stroke="#000" stroke-width="28"/><line x1="406.41" x2="389.3" y1="641.68" y2="684.28" stroke="#000" stroke-width="28"/><line transform="matrix(.2058 .97859 .97859 -.2058 155 615.61)" x2="45.906" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.30003 .95393 .95393 -.30003 92.681 418.58)" x2="206.33" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="403.73" x2="138.74" y1="675.44" y2="652.26" stroke="#000" stroke-width="28"/><path d="m290.08 639.43 127.87 11.187 2.44-27.893-109.52-9.582-20.791 26.288z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="325.44" x2="328.32" y1="629.45" y2="596.56" stroke="#000" stroke-width="28"/><path d="m256.57 636.47-127.87-11.188 2.44-27.893 109.52 9.582 15.911 29.499z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="226.82" x2="229.7" y1="620.82" y2="587.94" stroke="#000" stroke-width="28"/><line x1="317.14" x2="237.44" y1="609.65" y2="602.67" stroke="#000" stroke-width="28"/><line transform="matrix(-.29748 -.95473 -.95473 .29748 503.27 275.6)" x2="206.33" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.2058 -.97859 -.97859 .2058 442.23 78.57)" x2="45.906" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="190.82" x2="207.92" y1="52.495" y2="9.8954" stroke="#000" stroke-width="28"/><line x1="95.801" x2="190.94" y1="234.48" y2="51.394" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 457.93 55.925)" x2="266" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><path d="m340.97 57.71 127.87 11.187-2.44 27.893-109.52-9.5818-15.91-29.499z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line transform="matrix(-.087156 .9962 .9962 .087156 388.01 74.903)" x2="33.015" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><path d="m307.46 54.806-127.87-11.187-2.44 27.893 109.52 9.5818 20.792-26.288z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line transform="matrix(-.087156 .9962 .9962 .087156 289.39 66.274)" x2="33" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 361.23 105.69)" x2="80" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="64.139" x2="26.284" y1="357.64" y2="354.33" stroke="#000" stroke-width="28"/><line x1="62.656" x2="31.774" y1="294.27" y2="291.57" stroke="#000" stroke-width="28"/><line x1="24.067" x2="31.998" y1="368.19" y2="277.53" stroke="#000" stroke-width="28"/><circle transform="rotate(185 296.7 349.88)" cx="296.7" cy="349.88" r="172" stroke="#000" stroke-width="14"/>';
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