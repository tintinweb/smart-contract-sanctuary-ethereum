/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

/*
      ::::::::   ::::::::  ::::    :::  ::::::::   ::::::::  :::        ::::::::::          ::::    ::: :::::::::: ::::::::::: 
    :+:    :+: :+:    :+: :+:+:   :+: :+:    :+: :+:    :+: :+:        :+:                 :+:+:   :+: :+:            :+:      
   +:+        +:+    +:+ :+:+:+  +:+ +:+        +:+    +:+ +:+        +:+                 :+:+:+  +:+ +:+            +:+       
  +#+        +#+    +:+ +#+ +:+ +#+ +#++:++#++ +#+    +:+ +#+        +#++:++#            +#+ +:+ +#+ :#::+::#       +#+        
 +#+        +#+    +#+ +#+  +#+#+#        +#+ +#+    +#+ +#+        +#+                 +#+  +#+#+# +#+            +#+         
#+#    #+# #+#    #+# #+#   #+#+# #+#    #+# #+#    #+# #+#        #+#                 #+#   #+#+# #+#            #+#          
########   ########  ###    ####  ########   ########  ########## ##########          ###    #### ###            ###           
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Console_V28_Riddle is Ownable {

    string private hash;
    string private finalPhraseCompare;
    string private finalPhrase;
    address private __address;

    ///////////////////////////////////////////////////////////// owner
    function setHash(string memory newHash) external onlyOwner {
          hash = newHash;
    }    
    function setfinalPhraseCompare(string memory newfinalPhraseCompare) external onlyOwner {
          finalPhraseCompare = newfinalPhraseCompare;
    }
    function setfinalPhrase(string memory newfinalPhrase) external onlyOwner {
          finalPhrase = newfinalPhrase;
    }
    function setAddr(address _address) external onlyOwner {
          __address = _address; // 3rd
    }

    ///////////////////////////////////////////////////////////// riddle
    function returnHash() public view returns(string memory){
        return hash;
    }

    function returnFinalPhrase(string memory decryptedHash) public view returns(string memory){
       require( keccak256(abi.encodePacked((decryptedHash))) == keccak256(abi.encodePacked((finalPhraseCompare)) ),"Incorrect decryption");
       return finalPhrase;        
    }

}