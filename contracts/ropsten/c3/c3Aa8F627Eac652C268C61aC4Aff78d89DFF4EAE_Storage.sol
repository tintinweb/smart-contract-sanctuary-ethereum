/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;


interface iPartA {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartB {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartC {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartD {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartE {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartF {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartG {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartH {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartI {
    function GetPart(uint32 songPart) external view returns (string memory);
}

interface iPartJ {
    function GetPart(uint32 songPart) external view returns (string memory);
}

contract Storage {

    uint256 songParts = 487;

    string testString = "Hello ";

    address addressA;
    address addressB;
    address addressC;
    address addressD;
    address addressE;
    address addressF;
    address addressG;
    address addressH;
    address addressI;
    address addressJ;

    function setAddresses(address newAddressA, address newAddressB, 
        address newAddressC, address newAddressD, address newAddressE, 
        address newAddressF, address newAddressG, address newAddressH, 
        address newAddressI, address newAddressJ) public {
        addressA = newAddressA;
        addressB = newAddressB;
        addressC = newAddressC;
        addressD = newAddressD;
        addressE = newAddressE;
        addressF = newAddressF;
        addressG = newAddressG;
        addressH = newAddressH;
        addressI = newAddressI;
        addressJ = newAddressJ;
        PartA = iPartA(addressA);
        PartB = iPartB(addressB);
        PartC = iPartC(addressC);
        PartD = iPartD(addressD);
        PartE = iPartE(addressE);
        PartF = iPartF(addressF);
        PartG = iPartG(addressG);
        PartH = iPartH(addressH);
        PartI = iPartI(addressI);
        PartJ = iPartJ(addressJ);
     } 

    // address is address of deployed part A
    iPartA public PartA =  iPartA(addressA);
    iPartB public PartB =  iPartB(addressB);
    iPartC public PartC =  iPartC(addressC);
    iPartD public PartD =  iPartD(addressD);
    iPartE public PartE =  iPartE(addressE);
    iPartF public PartF =  iPartF(addressF);
    iPartG public PartG =  iPartG(addressG);
    iPartH public PartH =  iPartH(addressH);
    iPartI public PartI =  iPartI(addressI);
    iPartJ public PartJ =  iPartJ(addressJ);

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public returns (string memory){
        string memory result = "";
        for (uint i=0; i < 3; i += 1) {
            for (uint32 j=0; j<50; j += 1) {
                if (i == 0) {
                    string.concat(result, PartA.GetPart(j));
                } else if (i == 1) {
                    string.concat(result, PartB.GetPart(j));
                } else if (i == 2) {
                    string.concat(result, PartC.GetPart(j));
                } else if (i == 3) {
                    string.concat(result, PartD.GetPart(j));
                } else if (i == 4) {
                    string.concat(result, PartE.GetPart(j));
                } else if (i == 5) {
                    string.concat(result, PartF.GetPart(j));
                } else if (i == 6) {
                    string.concat(result, PartG.GetPart(j));
                } else if (i == 7) {
                    string.concat(result, PartH.GetPart(j));
                } else if (i == 8) {
                    string.concat(result, PartI.GetPart(j));
                } else if (i == 9 && j < 37) {
                    string.concat(result, PartJ.GetPart(j));
                }
            }
        }
        return result;
    }
}