// SPDX-License-Identifier: MIT 
// @author: @CoolMonkes - Monkestake - Staking
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ........................                                 .......................
// ........................ %%%,,,,,,,,,,,,,,,,,,,,,,,,,%%  .......................
// ........................ %%%,,,,,,,,,,,,,,,,,,,,,,,,,%%  .......................
// .......................  ///.........................//   ......................
// ....................... %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ......................
// .......................               /   /               ......................
// ........................ %%%,,,,,,,.. %%%%% .,,,,,,,,%%  .......................
// ........................ %%%........,...............,%%  .......................
// ........................ %%%,,,,,,,,,,,,,,,,,,,,,,,,,%%  .......................
// ........................ %%%,,,,,,,,,,,,,,,,,,,,,,,,,%%  .......................
// ....................... %%%&&&%%%&&&&&&&&&&&&&&&&&&&&&&%% ......................
// ....................... %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ......................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// ................................................................................
// Features:
// Secure signed stake function for extra security 
// Batch staking & unstaking to lower gas fees

pragma solidity ^0.8.11;

import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

interface IMonkes {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

interface IBoosts {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

contract Monkestake is Ownable, IERC721Receiver, Pausable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address public constant enforcerAddress = 0xD8A7fd1887cf690119FFed888924056aF7f299CE;

    address public monkeAddress;
    address public boostAddress;

    //Store token, owner, and stake timestamp
    struct Stake {
        uint16 tokenId;
        address owner;
        uint80 value;
    }

    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Maps tokenIds to stake
    mapping(uint256 => Stake) public monkeStaked;
    mapping(uint256 => Stake) public boostStaked;

    function setMonkeAddress(address contractAddress) public onlyOwner {
        monkeAddress = contractAddress;
    }

    function setBoostAddress(address contractAddress) public onlyOwner {
        boostAddress = contractAddress;
    }

    //Returns nounce for earner to enable transaction parity for security, next nounce has to be > than this value!
    function stakerCurrentNounce(address staker) public view returns (uint256) {
        return nounceTracker[staker];
    }

     function getMessageHash(address _to, uint _amount, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _nounce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    } 

    function stake(address account, uint16[] calldata monkeTokenIds,  uint16[] calldata boostTokenIds, uint amount, uint nounce, bytes memory signature) public whenNotPaused {
        require(account == _msgSender() || _msgSender() == boostAddress, "Can only stake to your own benefit!");
        
        if (_msgSender() != boostAddress) {
            require(nounceTracker[_msgSender()] < nounce, "Can not repeat a prior transaction!");
            require(verify(enforcerAddress, _msgSender(), amount, nounce, signature) == true, "Staking must be done from our website!");
            nounceTracker[_msgSender()] = nounce;

            for (uint i = 0; i < monkeTokenIds.length; i++) {
                require(IMonkes(monkeAddress).ownerOf(monkeTokenIds[i]) == _msgSender(), "Token does not belong to you");
                IMonkes(monkeAddress).transferFrom(_msgSender(), address(this), monkeTokenIds[i]);

                monkeStaked[monkeTokenIds[i]] = Stake({
                    owner: account,
                    tokenId: uint16(monkeTokenIds[i]),
                    value: uint80(block.timestamp)
                });
            }
        }

        for (uint i = 0; i < boostTokenIds.length; i++) {
            if (_msgSender() != boostAddress) {
                require(IBoosts(boostAddress).ownerOf(boostTokenIds[i]) == _msgSender(), "Token does not belong to you");
                IBoosts(boostAddress).transferFrom(_msgSender(), address(this), boostTokenIds[i]);
            }

            boostStaked[boostTokenIds[i]] = Stake({
                owner: account,
                tokenId: uint16(boostTokenIds[i]),
                value: uint80(block.timestamp)
            });
        }
    }
    
    function unstake(uint16[] calldata monkeTokenIds,  uint16[] calldata boostTokenIds, uint amount, uint nounce, bytes memory signature) public whenNotPaused {
        require(nounceTracker[_msgSender()] < nounce, "Can not repeat a prior transaction!");
        require(verify(enforcerAddress, _msgSender(), amount, nounce, signature) == true, "Unstaking must be done from our website!");
        nounceTracker[_msgSender()] = nounce;

        for (uint i = 0; i < monkeTokenIds.length; i++) {
            require(monkeStaked[monkeTokenIds[i]].owner == _msgSender(), "Token does not belong to you");
            IMonkes(monkeAddress).safeTransferFrom(address(this), _msgSender(), monkeTokenIds[i], "");
            delete monkeStaked[monkeTokenIds[i]];
        }

        for (uint i = 0; i < boostTokenIds.length; i++) {
            require(boostStaked[boostTokenIds[i]].owner == _msgSender(), "Token does not belong to you");
            IBoosts(boostAddress).safeTransferFrom(address(this), _msgSender(), boostTokenIds[i], "");
            delete boostStaked[boostTokenIds[i]];
        }
    }


    function emergencyRescue(address account, uint16[] calldata monkeTokenIds, uint16[] calldata boostTokenIds) public onlyOwner {

        for (uint i = 0; i < monkeTokenIds.length; i++) {
            IMonkes(monkeAddress).safeTransferFrom(address(this), account, monkeTokenIds[i], "");
            delete monkeStaked[monkeTokenIds[i]];
        }

        for (uint i = 0; i < boostTokenIds.length; i++) {
            IBoosts(boostAddress).safeTransferFrom(address(this), account, boostTokenIds[i], "");
            delete boostStaked[boostTokenIds[i]];
        }

    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Monkestake directly");
      return IERC721Receiver.onERC721Received.selector;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
  
}