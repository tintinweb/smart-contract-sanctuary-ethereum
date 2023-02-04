/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IERC1155BurnableExtension {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    // function burnBatch(
    //     address account,
    //     uint256[] memory ids,
    //     uint256[] memory values
    // ) external;

    // function burnByFacet(
    //     address account,
    //     uint256 id,
    //     uint256 amount
    // ) external;

    // function burnBatchByFacet(
    //     address account,
    //     uint256[] memory ids,
    //     uint256[] memory values
    // ) external;
}

contract MyToken {
    IERC1155BurnableExtension public tokenAddress;
    address public owner;

    constructor(address _tokenAddress){
      tokenAddress = IERC1155BurnableExtension(_tokenAddress);
     owner = msg.sender;
    }
    function burn1(address account, uint256 id, uint256 value) public virtual {
        // require(
        //     account == msg.sender || isApprovedForAll(account, msg.sender),
        //     "ERC1155: caller is not token owner or approved"
        // );

        tokenAddress.burn(account, id, value);
    }
    function changeTokenAddress(address _newTokenAddress)external{
      require(msg.sender==owner,"Only owner can call this funcion");
       tokenAddress = IERC1155BurnableExtension(_newTokenAddress);
    }
}