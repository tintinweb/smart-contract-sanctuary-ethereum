// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC1155.sol";
import "./Lux.sol";

/// @title Lux mint is one of 2 minting contracts for the Lux dro by DK
// It will handle the minting process for the multi editions
/// @author @smartcontrart
/// @notice The contract is to be used for the sole purpose of minting Lux multi edition tokens
// It has 2 main minting functionalities.
// 1 An offchain allow-list system
// 2 A mint process requiering a burn

contract LuxMint{
    uint256 public _ALMintPrice = 0.1*10**18;

    address public _luxAddress;
    address public _OSAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address public _signer;
    address public _recipient;

    bool public _ALMintOpened;
    bool public _burnMintOpened;
    bool public _burnRequired = true;

    mapping(address => bool) public _isAdmin;
    mapping(address => bool) public _hasMintedALToken;
    mapping(address => bool) public _hasMintedBurnToken;

    constructor(){
        _isAdmin[msg.sender]=true;
    }
    
    function setSigner (address signer) external{
        require(_isAdmin[msg.sender], "Only Admins can set signer");
        _signer = signer;
    }

    function setLuxAddress(address luxAddress) external{
        require(_isAdmin[msg.sender], "Only Admins can set LuxAddress");
        _luxAddress = luxAddress;
    }

    function setOSAddress(address OSAddress) external{
        require(_isAdmin[msg.sender], "Only Admins can set OSAddress");
        _OSAddress = OSAddress;
    }

    function setRecipient(address recipient) external{
        require(_isAdmin[msg.sender], "Only Admins can set the recipient");
        _recipient = recipient;
    }

    function toggleALMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle AL Mint");
        _ALMintOpened = !_ALMintOpened;
    }

    function toggleBurnMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle burn Mint");
        _burnMintOpened = !_burnMintOpened;
    }

    function toggleBurnRequired() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle _burnRequired");
        _burnRequired = !_burnRequired;
    }

    function mintAllowed(uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    _luxAddress,
                                    _ALMintOpened,
                                    _hasMintedALToken[msg.sender] // Should be false
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }


    function ALMint(
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external payable{
        require(mintAllowed(v, r, s), "Mint not allowed");
        require(msg.value >= _ALMintPrice, "Not enough funds");
        payable(_recipient).transfer(_ALMintPrice);
        Lux(_luxAddress).mint(msg.sender, 2, 1);
        _hasMintedALToken[msg.sender] = true;
    }

    function burnMint(
        uint256 tokenToBurn
    ) external payable{
        require(tokenToBurn == 20120243526926311683519745435316742329827468478987451852585008394345891495947 ||
                tokenToBurn == 20120243526926311683519745435316742329827468478987451852585008395445403123749 ||
                tokenToBurn == 20120243526926311683519745435316742329827468478987451852585008393246379868164 ||
                tokenToBurn == 20120243526926311683519745435316742329827468478987451852585008397644426379284 ||
                tokenToBurn == 20120243526926311683519745435316742329827468478987451852585008396544914751506 );
        // Tokens eligible for burn:
        // BROKEN //
        // 20120243526926311683519745435316742329827468478987451852585008394345891495947

        // SURRENDER /
        // 20120243526926311683519745435316742329827468478987451852585008395445403123749

        // CERTITUDE
        // 20120243526926311683519745435316742329827468478987451852585008393246379868164

        // ETERNAL 
        // 20120243526926311683519745435316742329827468478987451852585008397644426379284

        // DEVOTED
        // 20120243526926311683519745435316742329827468478987451852585008396544914751506
        require(_burnMintOpened, "Mint closed");
        require(_hasMintedBurnToken[msg.sender] == false, "Can only mint one token");
        // require(msg.value >= _burnMintPrice, "Not enough funds");
        if(_burnRequired){
            IERC1155(_OSAddress).safeTransferFrom(
                msg.sender, 
                0x000000000000000000000000000000000000dEaD, 
                tokenToBurn, 
                1, 
                "0x0");
        }
         Lux(_luxAddress).mint(msg.sender, 3, 1);
         _hasMintedBurnToken[msg.sender] = true;
    }
}