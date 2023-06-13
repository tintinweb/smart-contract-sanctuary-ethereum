// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract RSAGroth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 13267471056128263595757492079482622191367857762909395875792268836806967250376;
    uint256 constant alphay  = 8767989639018376981457420140300089120842648601069647485900894544299672075126;
    uint256 constant betax1  = 3251923658087934720111226877959742583426905417730938289592573350091259113387;
    uint256 constant betax2  = 16041511064342502221898449236436623670936776172759470516757735531110453659511;
    uint256 constant betay1  = 20426496985576601037043576662921595671620067069629392793694266293791775607342;
    uint256 constant betay2  = 6575098338289763705513852994988400758063744422682041543477828376559968516328;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 21679669957258237195814706909769294150239214192529808358150676110495098600652;
    uint256 constant deltax2 = 13062380359465889136304451833405448302846141605606908653207634779269598039877;
    uint256 constant deltay1 = 2470069538843451262889744542531634557794912224556206225807283764822454994389;
    uint256 constant deltay2 = 12729729067297308605784319070162658578152304782684431523836697816713203338163;

    
    uint256 constant IC0x = 2702433223736330281261947682995565678772445492236813123305496448250670144077;
    uint256 constant IC0y = 5235899564500624330004653983320439580003291152846202109543886548710768802521;
    
    uint256 constant IC1x = 21630685123758305146388940045071705833303546445642433935696209037776041457075;
    uint256 constant IC1y = 16054260105331811841693483941120860693689740283374523835172071199365497330385;
    
    uint256 constant IC2x = 7043509633229904376349034501776159576336403258078045758522680338505106573803;
    uint256 constant IC2y = 7067807587485211228440475717584916305320275141747207211076631082411077030959;
    
    uint256 constant IC3x = 10795891123562101609876789315558401416685767593699832205101498378225203738038;
    uint256 constant IC3y = 9966032080616745185577752372088598574569895227201456693511917336395191709654;
    
    uint256 constant IC4x = 15252458859651179499232804574057181065420637091637039993192915641508788343258;
    uint256 constant IC4y = 3257200891058300153286422689366471776549398690850537342537187507874046400004;
    
    uint256 constant IC5x = 20694699998923263995066815696826506015555366904666050078386493683418182407195;
    uint256 constant IC5y = 5428089695821817606348286164295609384883170054709602587502028236830330097075;
    
    uint256 constant IC6x = 7300625234261108388155148976779437911047009535420328176369962864803820591656;
    uint256 constant IC6y = 12556482623117484688721713002823354895264891743048479881375318224878677284609;
    
    uint256 constant IC7x = 4155776798624572804801856343781824905472729593533293082458328007524911003281;
    uint256 constant IC7y = 3318836433060565254660456378984173892900829298338992676190893172353846715422;
    
    uint256 constant IC8x = 18917391510818593131497636717514760378657685776767428505649244817133926480679;
    uint256 constant IC8y = 6412504339474895230979394323375092950750279037639373348391127250153647853688;
    
    uint256 constant IC9x = 6799285167132076213869897343301522337425219689915384248150910967021668470748;
    uint256 constant IC9y = 4385486491505460287935973468318991521964744740433547360825608324742815870044;
    
    uint256 constant IC10x = 14392729960095963086935465025209890386226560309228994347838683616005240660399;
    uint256 constant IC10y = 11269093005478898947035168482651550366786768386437177614016665293497920154732;
    
    uint256 constant IC11x = 17208630843946943940074961985575591374283395414462048926592541853181043795180;
    uint256 constant IC11y = 4623640403419432024224381260198461916531115313292316895445925755117796441723;
    
    uint256 constant IC12x = 3313560126089188928014152622680446999465367253845193424310694322345350565583;
    uint256 constant IC12y = 4427972935171049741889575341555972313337213766152059363388418723313618121725;
    
    uint256 constant IC13x = 12491074544919958583195368859705434068298846558893024927279830315031675233235;
    uint256 constant IC13y = 740909148540950706864100492708869203481785693961459798584478123251916027234;
    
    uint256 constant IC14x = 20311612628157380081723602798422631438301849200582486606247993347337542958835;
    uint256 constant IC14y = 6972415113504434422630501387728553349582999178162868474625495922911635989616;
    
    uint256 constant IC15x = 13781470372392104799994977137072221924982588609026336040425885517615004208349;
    uint256 constant IC15y = 17389040017067057159320597274373494827634276250842905788615532041251895083734;
    
    uint256 constant IC16x = 4113695265260687984390415829228967714537589192994264855825510992030061615560;
    uint256 constant IC16y = 15278073746139822579408939341264564601379964989724331189972405933656304801301;
    
    uint256 constant IC17x = 17817356419405054505346184060869593708007275360898835421495257717009830625223;
    uint256 constant IC17y = 12593028072036547141945219574760679042907767721144271921269958713772518621775;
    
    uint256 constant IC18x = 17516278418063122561295886779638506110032266094534908404780442063925350665047;
    uint256 constant IC18y = 5538856462715068408086095349603448916487795719984154042632314881628255559034;
    
    uint256 constant IC19x = 47013341203649631850411568578488977002369258844984089350699487677462859015;
    uint256 constant IC19y = 5829358810119076566321108287674326341310237000576369489504450348201202877651;
    
    uint256 constant IC20x = 6895566129978509684120523275876925831219487886079662929412630323969930131105;
    uint256 constant IC20y = 20599028767517058412223235469209069882370083145931864464284174326908165283096;
    
    uint256 constant IC21x = 11968687385878265971322360170804757376189351681686687002546462672343891482689;
    uint256 constant IC21y = 263570020885171621217608333775316699183693115236455411037750696881494910533;
    
    uint256 constant IC22x = 4995707757333178693141727713871233753773629382636886143642881493023391842890;
    uint256 constant IC22y = 4685879740479532702416975011250767488151200382936876465823502272542355932296;
    
    uint256 constant IC23x = 3663707002483606473388666108743635920819809261283804620913743211512394736504;
    uint256 constant IC23y = 14578846953919487518222332614915985682078463742823365452265063977669765862717;
    
    uint256 constant IC24x = 2546132007923120714203541680149443804883555235060736212528951039460001878857;
    uint256 constant IC24y = 4281822412207817622162243284693006751392146120551623017441520173479524558813;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[24] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }