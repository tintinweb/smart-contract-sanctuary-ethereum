/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

interface IERC1271 {

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

library SignatureChecker {
    
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

abstract contract SignatureCheckerMock {
    using SignatureChecker for address;

    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        return signer.isValidSignatureNow(hash, signature);
    }
}

contract GamePolkawar is Ownable, SignatureCheckerMock {

    IERC20 public USDC;
    address public signer;
    uint256 public currentBattle;
    uint256 public beneficiaryFee = 100;
    address public beneficiaryAddress;

    struct battleDetails{
        uint256 battleID;
        address player1;
        address player2;
        uint256 NFTid1;
        uint256 NFTid2;
        uint256 depositAmount;
        uint256 winningTime;
        bool battleClosed;
    }

    struct battleCosmetics{
        string name;
        uint256[] levelFee;
    }

    struct Warrior{
        uint256 warriorID;
        string cosmeticName;
        uint256 cosmeticID;
        uint256 cosmeticLevel;
    }

    mapping(uint256 => battleCosmetics) private upgradeCosmetics;
    mapping(uint256 => battleDetails) public battleSlots;
    mapping(uint256 => mapping(uint256 => Warrior)) private warriorCosmeticLevel; 
    mapping(bytes32 => bool) public isVerifyHash;

    event UpdateCosmeticLevel(Warrior battleCosmetic, address indexed owner);
    event CreateBattle(battleDetails BattleCreation, address indexed battleCreator);
    event JoinBattle(battleDetails BattleJoin, address indexed joiningPlayer);
    event RewardClaiming(address indexed winner, uint256 battleID, uint256 winningAmount);
    event recoverBattleSlot(battleDetails battleSlot, address playerAddress, uint256 );
    event EmergencySafe(address indexed caller, address indexed TokenAddress,address indexed receiver, uint256 tokenAmount);

    constructor(address _USDC, address _signer, address _beneficiaryAddress) {
        USDC = IERC20(_USDC);
        signer = _signer;
        beneficiaryAddress = _beneficiaryAddress;
    }

    function updateUSDC(address _USDC) external onlyOwner{
        require(address(0x0) != _USDC,"Invalid address");
        USDC = IERC20(_USDC);
    }

    function updateBeneficiaryFee(uint256 newFee) external onlyOwner{
        beneficiaryFee = newFee;
    }

    function updateSigner(address _signer) external onlyOwner{
        require(address(0x0) != _signer,"Invalid address");
        signer = _signer;
    }

    function updateBeneficiaryAddress(address _beneficiaryAddress) external onlyOwner{
        require(address(0x0) != _beneficiaryAddress,"Invalid address");
        beneficiaryAddress = _beneficiaryAddress;
    }

    function updateCosmetics(uint256 cosmeticsID,battleCosmetics calldata _battleCosmeticsParams) external onlyOwner {
        upgradeCosmetics[cosmeticsID] = _battleCosmeticsParams;
    }

    function viewCosmeticLevel(uint256 ID) external view returns(battleCosmetics memory){
        return upgradeCosmetics[ID];
    }

    function viewNFTCosmeticLevel(uint256 cosmeticID, uint256 NFTID) external view returns(Warrior memory){
        return warriorCosmeticLevel[cosmeticID][NFTID];
    }

    function updateCosmeticLevel(uint256 cosmeticID, uint256 _tokenAmount,uint256 NFT_ID, bytes memory _signature) external {
        Warrior storage warrior = warriorCosmeticLevel[cosmeticID][NFT_ID];
        battleCosmetics storage cosmetic = upgradeCosmetics[cosmeticID];
        bytes32 hash = getUpgradeHash(msg.sender, cosmeticID,NFT_ID, _tokenAmount);
        validateHash(hash);
        isValidSignatureNow(signer,hash,_signature);
        if(warrior.cosmeticLevel == 0){
            warrior.warriorID = NFT_ID;
            warrior.cosmeticID = cosmeticID;
            warrior.cosmeticName = cosmetic.name;
        }
        warrior.cosmeticLevel = warrior.cosmeticLevel++;
        require(cosmetic.levelFee[warrior.cosmeticLevel] <= _tokenAmount,"Invalid token Amount");
        USDC.transferFrom(_msgSender(), address(this), _tokenAmount);

        emit UpdateCosmeticLevel(warrior, msg.sender);
    }

    function openBattleSlot(uint256 _NFTID, uint256 _amount) external {
        currentBattle++;

        battleDetails storage battle = battleSlots[currentBattle];
        battle.player1 = _msgSender();
        battle.NFTid1 = _NFTID;
        battle.battleID = currentBattle;
        battle.depositAmount = _amount;

        require(USDC.transferFrom(_msgSender(),address(this),_amount),"Invalid Token Approve Amount" );

        emit CreateBattle(battle, msg.sender);
    }

    function joinBattle(uint256 _NFTID, uint256 _battleID) external {
        battleDetails storage battle = battleSlots[_battleID];

        require(battle.player1 != _msgSender(),"both player are same");
        require(battle.player2 == address(0x0),"Battle slot full");
        
        battle.player2 = _msgSender();
        battle.NFTid2 = _NFTID;

        require(USDC.transferFrom(_msgSender(),address(this),battle.depositAmount),"Invalid Token Approve Amount");

        emit JoinBattle(battle, msg.sender);
    }

    function claimWinningReward(address battleWinner,uint256 _battleID, uint256 _deadLine, bytes memory signature) external {
        battleDetails storage battle = battleSlots[_battleID];
        require(!battle.battleClosed, "battle already closed");
        require(battleWinner != address(0x0),"zero address is not battle winner");
        bytes32 hash = getWinnerHash(_battleID, _deadLine);
        battle.battleClosed = true;
        validateHash(hash);
        isValidSignatureNow(signer,hash ,signature);
        
        uint256 Fee = battle.depositAmount * 2 * beneficiaryFee / 1000; //take benificiry fee.
        
        USDC.transfer(_msgSender(),(battle.depositAmount - Fee));

        emit RewardClaiming(battleWinner, _battleID, (battle.depositAmount - Fee) );
    }

    function finishBattle(uint256 battleID, uint256 playerNum) external onlyOwner {
        require(playerNum > 0 && playerNum < 3,"Invalid player Number");
        battleDetails storage battle = battleSlots[battleID];
        battle.battleClosed = true;
        address user;
        if(playerNum == 1) { user = battle.player1; }
        else {user = battle.player2; }
        uint256 Fee = battle.depositAmount * beneficiaryFee / 1000; //take benificiry fee.
        USDC.transfer(user,(battle.depositAmount - Fee));

        emit recoverBattleSlot(battle, user, (battle.depositAmount - Fee));

    }

    function getUpgradeHash(address _account, uint256 _cosmeticID,uint256 NFT_ID, uint256 _tokenAmount) public view returns(bytes32 ){
        return keccak256(abi.encodePacked(abi.encodePacked(address(this), _account, _cosmeticID, NFT_ID, _tokenAmount)));
    }

    function validateHash(bytes32 Hash) internal {
        require(!isVerifyHash[Hash],"Hash already used");
        isVerifyHash[Hash] = true;
    }

    function getWinnerHash(uint256 _battleID, uint256 _deadLine) public view returns(bytes32 ){
        battleDetails storage battle = battleSlots[_battleID];
        return keccak256(abi.encodePacked(abi.encodePacked(address(this), battle.player1, battle.player2,_deadLine)));
    }

    function emergency(address _tokenAddress,address _to, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_tokenAmount),"emergency :: transaction failed");
        }else{
            IERC20(_tokenAddress).transfer(_to, _tokenAmount);
        }

        emit EmergencySafe(msg.sender, _tokenAddress, _to, _tokenAmount);
    }

}