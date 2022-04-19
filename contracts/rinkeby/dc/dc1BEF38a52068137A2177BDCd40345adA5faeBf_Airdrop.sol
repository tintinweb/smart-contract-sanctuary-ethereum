// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Airdrop is Ownable {
    address public signerAddress;
    IERC20 internal better;
    IERC20 internal holdingToken;
    uint256 public tokenMinHold;
    IERC721 internal holdingNFT;
    uint256 public nftMinHold;

    mapping(string => bool) public usedIP;
    mapping(address => bool) public usedAddresses;

    uint256 public totalDropLimit;
    uint256 public userDropLimit;
    uint256 public totalDropped;
    
    event AirDropped(
        address indexed userAddress,
        uint256 amount
    );

    event DropLimitUpdated( uint256 newLimit );
    event TokenHoldingLimitUpdated(uint256 newTokenLimit);
    event NFTHoldingLimitUpdated(uint256 newNFTLimit);
    event UserDropLimitUpdated(uint256 newLimit);

    constructor(address _signerAddress, address _tokenAddress, uint256 userdropLimit_, uint256  totalDropLimit_) {
        require(
            _signerAddress != address(0),
            "Signer Address could not be empty"
        );
        require(
            _tokenAddress != address(0),
            "Token Address could not be empty"
        );

        signerAddress = _signerAddress;
        better = IERC20(_tokenAddress);
        userDropLimit = userdropLimit_;
        totalDropLimit = totalDropLimit_;
    }

    /**
     * @dev public function to get Better token airdrop.
     * takes userIp address and verified signature value as input. 
     */
    function getAirdrop(
        string memory userIP_,
        bytes memory signature_
    ) public returns (bool) {
        require(totalDropped + userDropLimit <= totalDropLimit, "Airdrop max Limit reached");
        require(!usedIP[userIP_], "Ip already used");
        require(!usedAddresses[msg.sender], "Address already used");

        if (tokenMinHold > 0){
            require(holdingToken.balanceOf(msg.sender) >= tokenMinHold, "Not enough token holdings");
        }
        if (nftMinHold > 0){
            require(holdingNFT.balanceOf(msg.sender) >= nftMinHold, "Not enough NFT holdings");
        }

        address recoveredAddress = recoverSigner(
            keccak256(abi.encodePacked(msg.sender, userIP_, userDropLimit)),
            signature_
        );

        require(recoveredAddress == signerAddress, "Invalid signature");
        usedAddresses[msg.sender] = true;
        usedIP[userIP_] = true;
        totalDropped += userDropLimit;

        better.transfer(msg.sender, userDropLimit);
        
        emit AirDropped(msg.sender, userDropLimit);
        return true;
    }

//  ================= Admin functions ========================
    function updateTotalDropLimit(uint256 newLimit_)public onlyOwner returns(bool){
        require (newLimit_ > 0, "Limit can not be zero");
        totalDropLimit = newLimit_;
        emit DropLimitUpdated(newLimit_);
        return true;
    }

    function updateUserDropLimit(uint256 newLimit_)public onlyOwner returns(bool){
        require (newLimit_ > 0, "Limit can not be zero");
        userDropLimit = newLimit_;
        emit UserDropLimitUpdated(newLimit_);
        return true;
    }

//   admin functions to withdraw better tokens out of the contract.
    function adminWithdrawal(address userAddress, uint256 amount)public onlyOwner {
        require(userAddress != address(0), "User Address could not be empty");
        require(amount > 0, "Amount cannot be zero");

        better.transfer(userAddress, amount);
    }

// admin function to update the contract address of holding token
    function updateHoldingTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        holdingToken = IERC20(_tokenAddress);
    }

    function updateHoldingTokenAmount(uint256 _amount) public onlyOwner {
        tokenMinHold = _amount;
        emit TokenHoldingLimitUpdated(tokenMinHold);
    }

// admin function to update the contract address of holding NFT token
    function updateHoldingNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0), "Invalid contract address");
        holdingNFT = IERC721(_nftAddress);
    }

    function updateHoldingNFTAmount(uint256 _amount) public onlyOwner {
        nftMinHold = _amount;
        emit NFTHoldingLimitUpdated(nftMinHold);
    }

// admin function to update the address of message signer.
    function updateSignerAddress(address _signerAddress) public onlyOwner {
        require(
            _signerAddress != address(0),
            "Signer Address could not be empty"
        );
        signerAddress = _signerAddress;
    }

    // ============= helper functions ======================

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        message = prefixed(message);
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}