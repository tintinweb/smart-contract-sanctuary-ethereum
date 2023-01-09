//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SVG.sol";
import "./Utils.sol";
import "./Strings.sol";



// // last var between -20.754622 & +13.754622
// // second var between 5.237903 & -12.237903


// //                    happy         sad
// //                   > 2500        < 900


// //   1584563250285286751870879006720000             2640938750475477919784798344533333


// interface Uni {
//     function slot0() view external returns(uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
// }

contract Renderer {
    using Strings for uint256;

    function render(uint256 id, uint160 sqrtPriceX96) public view returns (string memory) {

        //Uni uniPrice = Uni(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);
        //(uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) =  uniPrice.slot0();


        uint p = 1000000000000/((uint(sqrtPriceX96) / (2**96))**2);
        string memory p1 = Strings.toString(p);
        string memory t = '';
        string memory t2 = '';
        string memory ti = Strings.toString(id);
        
        if(p < 900){
            t = '-12.237903';
            t2 = '+13.754622';
        }
        else if(p >= 900 && p < 1100){
            t = '-10.357903';
            t2 = '+10.154622';
        }        
        else if(p >= 1100 && p < 1300){
            t = '-8.477903';
            t2 = '+6.554622';
        }
        else if(p >= 1300 && p < 1500){
            t = '-6.597903';
            t2 = '+2.954622';
        }
        else if(p >= 1500 && p < 1700){
            t = '-4.717903';
            t2 = '-0.645378';
        }
        else if(p >= 1700 && p < 1900){
            t = '-2.837903';
            t2 = '-4.245378';
        }
        else if(p >= 1900 && p < 2100){
            t = '-0.957903';
            t2 = '-7.845378';
        }
        else if(p >= 1100 && p < 2300){
            t = '+0.922097';
            t2 = '-11.445378';
        }
        else if(p >= 2300 && p < 2500){
            t = '+2.802097';
            t2 = '-15.045378';
        }
        else if(p >= 2500 && p < 2700 ){
            t = '+4.682097';
            t2 = '-18.645378';
        }
        else{
            t = '+5.237903';
            t2 = '-20.754622';
        }



        return
            string.concat(
                '<svg id="ejbrX7hcI0m1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 -40 250 250" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" style="background-color:#e9d2f4"><style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style><path d="M43.532138,161.525794C26.211909,161.401111,14.270961,191.839849,16.44733,210h153.245886c.91561-1.477597.77527-15.559346,0-18.798493-2.374011-4.687895-12.852309-12.76429-19.670023-17.255565v-2.982799L43.532138,161.525794Z" fill="#3e5aad" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M44.222435,158.93565l-.690297,2.590143c22.65338,20.366154,97.998935,22.133799,102.285558,10.650476L44.222435,158.93565Z" transform="translate(.000001 0.000001)" fill="#588e3a" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M43.532136,158.49722c-7.193302-2.769057-10.444341-30.915268-7.740564-36.734878c1.581709-11.225501,14.605325-45.413136,25.878472-44.478717c3.526311-10.184046,12.206964-26.700433,22.245631-32.578418c12.443459-7.959621,35.430003-6.5256,45.862888,5.623036c18.43452-12.69121,43.619055-11.759689,46.917207,11.94895c4.87381,1.881459,16.467992,7.588132,15.519504,11.092933c3.398305,1.656981,7.47851,4.828263,6.431164,6.688412c1.419352,1.63023,3.250288,5.294635,3.197039,6.494117.462895,7.446375-2.526177,7.555465-2.682545,8.040315.140906,1.089141-.042849,2.199499-.304967,2.377076l-6.537007,3.932641c-1.935198,3.983228-8.503127,8.819683-12.97255,9.883848c5.881069,4.956369,12.77806,15.386767,12.426191,21.343545l-17.944995,23.381718c-2.564065,4.791131-13.218884,12.855194-24.756826,15.87742-29.31475,6.01402-82.30797,1.314429-105.538642-12.891998Z" transform="translate(.000002 0.000004)" fill="#588e3a" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M86.592717,64.41687c16.482487-13.850871,46.131488-8.494201,59.224979,11.506176l-1.502183,3.036121c5.412521-7.654394,30.962345-8.658517,47.899762-5.589037" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M198.64644,80.773196c-11.400157-7.255727-37.260528-8.153347-52.022301-.714654-20.590116-10.167056-41.921015-1.725712-51.29075,5.109402-2.498722-.131482-7.840703.072146-10.683962.341886q-1.131959,1.278591.488703,4.188393l9.351363.882692" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M94.708039,90.154346c5.621156-4.783526,14.123932-11.328923,20.88214-11.824138c17.079192-1.468538,27.595235.836671,32.91401,6.02218.839106,3.769071-.506592,7.799519-1.88005,9.33971-8.357155,12.318918-49.740308,5.340315-51.9161-3.537752" transform="translate(.000001 0)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M129.778565,50.328247l5.988827,12.44162c10.892791-1.784701,31.325951-2.403401,40.928379-.49267" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M135.767393,62.769867l-2.461097.888161" transform="translate(.000001 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M89.668593,81.453608c2.180419-.820613,5.097682-.692132,6.873883-2.494441c7.754278-7.868259,28.832931-12.042289,46.975652-6.156319" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M201.927627,87.209386c-1.639056-3.753661-11.334577-7.241307-18.245804-8.250221-19.985423-1.85188-36.330847,6.364466-35.813438,16.299794c10.247289,7.262045,36.067059,4.369992,51.292549-.665986c1.190259-.211368,2.673807-3.502358,2.766693-7.383587Z" transform="translate(0 0.000002)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M95.33339,98.342955c18.612914,8.414789,54.137873,11.294508,52.018152-4.650858" transform="translate(0 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M115.59018,116.452662c4.437639-1.281605,15.034965-6.561408,21.042576-10.179414" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M162.922898,114.452112l-11.368622-5.193579c7.037372,2.918569,21.908424,3.084569,29.730172.940569" transform="translate(0 0.000002)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M60.328241,89.698223l1.341804-13.125731" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M74.78809,149.078656c1.272988,4.142417,4.561915,9.521442,9.127587,9.856995" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="9.339762" ry="8.670245" transform="matrix(1.2 0 0 1.15 173.740726 89.3)" stroke-width="0"/><ellipse rx="10.153149" ry="10.25217" transform="matrix(1.1 0 0 1 119.6 89.7)" stroke-width="0"/><path d="M121.733431,85.167944c4.911004-.497861,3.369709,3.128709,1.523244,3.390027-1.301345-.124312-3.128018-2.686331-1.523244-3.390027Z" transform="translate(.000002 0.000003)" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="1.080641" ry="0.893174" transform="matrix(1.047442 0.073244-.069756 0.997564 116.294214 82.96638)" fill="#fff" stroke-width="0"/><ellipse rx="0.628259" ry="0.570124" transform="matrix(.987688 0.156434-.156434 0.987688 116.860169 89.128099)" fill="#fff" stroke-width="0"/><path d="M178.303345,87.921005c-1.061843.259131-2.076819.36987-2.999997,0-.215379-.6875-.223257-2.084292-.000003-2.753061.844646-.777778,1.884074-.767565,3-.034739.363815.683472.268946,2.021873,0,2.7878Z" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="0.91" ry="0.769518" transform="matrix(.987688 0.156434-.156434 0.987688 170.712392 88.823404)" fill="#fff" stroke-width="0"/><ellipse rx="1.490167" ry="1.344534" transform="translate(170.390167 82.744534)" fill="#fff" stroke-width="0"/>',
                svg.text(
                    string.concat(
                        svg.prop('x', '20'),
                        svg.prop('y', '10'),
                        svg.prop('font-size', '22'),
                        svg.prop('fill', 'white')
                    ),
                    string.concat(
                        '$',
                        svg.cdata(Strings.toString(p))
                    )
                ),
                svg.text(
                    string.concat(
                        svg.prop('x', '85'),
                        svg.prop('y', '205'),
                        svg.prop('font-size', '13'),
                        svg.prop('fill', 'white')
                    ),
                    string.concat(
                        '#',
                        svg.cdata(ti)
                    )
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),
                        svg.prop('transform', 'translate(.995091 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '22'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#a55d2b'),
                        svg.prop('stroke-width', '19'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '1.5'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                '<path d="M178.303344,136.60599c2.492544-.105922,9.961753-2.485239,13.469257-4.029921c9.403394,6.231565-4.706179,13.091591-15.076829,14.24343" transform="translate(.000001 0)" fill="#a55d2b" stroke="#000" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/><line x1="-103" y1="6" x2="-8" y2="6" transform="translate(125 14.074212)" fill="none" stroke="#800080" stroke-width="4.8" stroke-linecap="round"/>',
                '</svg>'
            );
    }
    


    function render2(uint256 _tokenId) public view returns (string memory) {

        // Uni uniPrice = Uni(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);
        // (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) =  uniPrice.slot0();
        uint160 sqrtPriceX96 = 123;

        uint p = 1000000000000/((uint(sqrtPriceX96) / (2**96))**2);
        //uint p = 990;
        string memory p1 = Strings.toString(p);
        string memory t = '';
        string memory t2 = '';
        uint id = _tokenId;
        
        if(p < 900){
            t = '-12.237903';
            t2 = '+13.754622';
        }
        else if(p >= 900 && p < 1100){
            t = '-10.357903';
            t2 = '+10.154622';
        }        
        else if(p >= 1100 && p < 1300){
            t = '-8.477903';
            t2 = '+6.554622';
        }
        else if(p >= 1300 && p < 1500){
            t = '-6.597903';
            t2 = '+2.954622';
        }
        else if(p >= 1500 && p < 1700){
            t = '-4.717903';
            t2 = '-0.645378';
        }
        else if(p >= 1700 && p < 1900){
            t = '-2.837903';
            t2 = '-4.245378';
        }
        else if(p >= 1900 && p < 2100){
            t = '-0.957903';
            t2 = '-7.845378';
        }
        else if(p >= 1100 && p < 2300){
            t = '+0.922097';
            t2 = '-11.445378';
        }
        else if(p >= 2300 && p < 2500){
            t = '+2.802097';
            t2 = '-15.045378';
        }
        else if(p >= 2500 && p < 2700 ){
            t = '+4.682097';
            t2 = '-18.645378';
        }
        else{
            t = '+5.237903';
            t2 = '-20.754622';
        }



        return
            string.concat(
                '<svg id="ejbrX7hcI0m1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 -40 250 250" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" style="background-color:#e9d2f4"><style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style><path d="M43.532138,161.525794C26.211909,161.401111,14.270961,191.839849,16.44733,210h153.245886c.91561-1.477597.77527-15.559346,0-18.798493-2.374011-4.687895-12.852309-12.76429-19.670023-17.255565v-2.982799L43.532138,161.525794Z" fill="#3e5aad" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M44.222435,158.93565l-.690297,2.590143c22.65338,20.366154,97.998935,22.133799,102.285558,10.650476L44.222435,158.93565Z" transform="translate(.000001 0.000001)" fill="#588e3a" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M43.532136,158.49722c-7.193302-2.769057-10.444341-30.915268-7.740564-36.734878c1.581709-11.225501,14.605325-45.413136,25.878472-44.478717c3.526311-10.184046,12.206964-26.700433,22.245631-32.578418c12.443459-7.959621,35.430003-6.5256,45.862888,5.623036c18.43452-12.69121,43.619055-11.759689,46.917207,11.94895c4.87381,1.881459,16.467992,7.588132,15.519504,11.092933c3.398305,1.656981,7.47851,4.828263,6.431164,6.688412c1.419352,1.63023,3.250288,5.294635,3.197039,6.494117.462895,7.446375-2.526177,7.555465-2.682545,8.040315.140906,1.089141-.042849,2.199499-.304967,2.377076l-6.537007,3.932641c-1.935198,3.983228-8.503127,8.819683-12.97255,9.883848c5.881069,4.956369,12.77806,15.386767,12.426191,21.343545l-17.944995,23.381718c-2.564065,4.791131-13.218884,12.855194-24.756826,15.87742-29.31475,6.01402-82.30797,1.314429-105.538642-12.891998Z" transform="translate(.000002 0.000004)" fill="#588e3a" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M86.592717,64.41687c16.482487-13.850871,46.131488-8.494201,59.224979,11.506176l-1.502183,3.036121c5.412521-7.654394,30.962345-8.658517,47.899762-5.589037" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M198.64644,80.773196c-11.400157-7.255727-37.260528-8.153347-52.022301-.714654-20.590116-10.167056-41.921015-1.725712-51.29075,5.109402-2.498722-.131482-7.840703.072146-10.683962.341886q-1.131959,1.278591.488703,4.188393l9.351363.882692" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M94.708039,90.154346c5.621156-4.783526,14.123932-11.328923,20.88214-11.824138c17.079192-1.468538,27.595235.836671,32.91401,6.02218.839106,3.769071-.506592,7.799519-1.88005,9.33971-8.357155,12.318918-49.740308,5.340315-51.9161-3.537752" transform="translate(.000001 0)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M129.778565,50.328247l5.988827,12.44162c10.892791-1.784701,31.325951-2.403401,40.928379-.49267" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M135.767393,62.769867l-2.461097.888161" transform="translate(.000001 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M89.668593,81.453608c2.180419-.820613,5.097682-.692132,6.873883-2.494441c7.754278-7.868259,28.832931-12.042289,46.975652-6.156319" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M201.927627,87.209386c-1.639056-3.753661-11.334577-7.241307-18.245804-8.250221-19.985423-1.85188-36.330847,6.364466-35.813438,16.299794c10.247289,7.262045,36.067059,4.369992,51.292549-.665986c1.190259-.211368,2.673807-3.502358,2.766693-7.383587Z" transform="translate(0 0.000002)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M95.33339,98.342955c18.612914,8.414789,54.137873,11.294508,52.018152-4.650858" transform="translate(0 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M115.59018,116.452662c4.437639-1.281605,15.034965-6.561408,21.042576-10.179414" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M162.922898,114.452112l-11.368622-5.193579c7.037372,2.918569,21.908424,3.084569,29.730172.940569" transform="translate(0 0.000002)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M60.328241,89.698223l1.341804-13.125731" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M74.78809,149.078656c1.272988,4.142417,4.561915,9.521442,9.127587,9.856995" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="9.339762" ry="8.670245" transform="matrix(1.2 0 0 1.15 173.740726 89.3)" stroke-width="0"/><ellipse rx="10.153149" ry="10.25217" transform="matrix(1.1 0 0 1 119.6 89.7)" stroke-width="0"/><path d="M121.733431,85.167944c4.911004-.497861,3.369709,3.128709,1.523244,3.390027-1.301345-.124312-3.128018-2.686331-1.523244-3.390027Z" transform="translate(.000002 0.000003)" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="1.080641" ry="0.893174" transform="matrix(1.047442 0.073244-.069756 0.997564 116.294214 82.96638)" fill="#fff" stroke-width="0"/><ellipse rx="0.628259" ry="0.570124" transform="matrix(.987688 0.156434-.156434 0.987688 116.860169 89.128099)" fill="#fff" stroke-width="0"/><path d="M178.303345,87.921005c-1.061843.259131-2.076819.36987-2.999997,0-.215379-.6875-.223257-2.084292-.000003-2.753061.844646-.777778,1.884074-.767565,3-.034739.363815.683472.268946,2.021873,0,2.7878Z" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="0.91" ry="0.769518" transform="matrix(.987688 0.156434-.156434 0.987688 170.712392 88.823404)" fill="#fff" stroke-width="0"/><ellipse rx="1.490167" ry="1.344534" transform="translate(170.390167 82.744534)" fill="#fff" stroke-width="0"/>',
                svg.text(
                    string.concat(
                        svg.prop('x', '20'),
                        svg.prop('y', '10'),
                        svg.prop('font-size', '22'),
                        svg.prop('fill', 'white')
                    ),
                    string.concat(
                        '$',
                        svg.cdata(Strings.toString(p))
                    )
                ),
                svg.text(
                    string.concat(
                        svg.prop('x', '85'),
                        svg.prop('y', '205'),
                        svg.prop('font-size', '13'),
                        svg.prop('fill', 'white')
                    ),
                    string.concat(
                        '#',
                        svg.cdata(Strings.toString(id))
                    )
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),
                        svg.prop('transform', 'translate(.995091 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '22'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#a55d2b'),
                        svg.prop('stroke-width', '19'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '1.5'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                '<path d="M178.303344,136.60599c2.492544-.105922,9.961753-2.485239,13.469257-4.029921c9.403394,6.231565-4.706179,13.091591-15.076829,14.24343" transform="translate(.000001 0)" fill="#a55d2b" stroke="#000" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/><line x1="-103" y1="6" x2="-8" y2="6" transform="translate(125 14.074212)" fill="none" stroke="#800080" stroke-width="4.8" stroke-linecap="round"/>',
                '</svg>'
            );
    }

    function example() external view returns (string memory) {
        return render(1, 123);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./Math.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return
            el(
                'image',
                string.concat(prop('href', _href), ' ', _props)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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