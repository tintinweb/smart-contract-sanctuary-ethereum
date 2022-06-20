/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Verification {
  address private _owner;
  address private signer;
  IERC20 private feeToken;
  uint private feeAmount;

  struct VerifiedPassport {
    uint expiration;
    bytes32 countryAndDocNumberHash;
  }

  struct PersonalDetails {
    bool over18;
    bool over21;
    uint countryCode;
  }

  mapping(address => VerifiedPassport) private accounts;
  mapping(address => PersonalDetails) private personalData;
  mapping(bytes32 => address) private idHashToAccount;
  mapping(address => uint) private hasPaidFee;

  event FeePaid(address indexed account);
  event VerificationUpdated(address indexed account, uint256 expiration);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event FeeTokenChanged(address indexed previousFeeToken, address indexed newFeeToken);
  event FeeAmountChanged(uint previousFeeAmount, uint newFeeAmount);
  event IsOver18(address indexed account);
  event IsOver21(address indexed account);
  event CountryOfOrigin(address indexed account, uint countryCode);

  constructor(address _signer, address _feeToken, uint _feeAmount) {
    require(_signer != address(0), "Signer must not be zero address");
    require(_feeToken != address(0), "Fee token must not be zero address");
    _transferOwnership(msg.sender);
    signer = _signer;
    feeToken = IERC20(_feeToken);
    feeAmount = _feeAmount;
  }

  function getFeeToken() external view returns (address) {
    return address(feeToken);
  }

  function getFeeAmount() external view returns (uint) {
    return feeAmount;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function payFeeFor(address account) public {
    emit FeePaid(account);
    hasPaidFee[account] = block.number;
    bool received = feeToken.transferFrom(msg.sender, address(this), feeAmount);
    require(received, "Fee transfer failed");
  }

  function payFee() external {
    payFeeFor(msg.sender);
  }

  function unsetPaidFee(address account) external onlyOwner {
    delete hasPaidFee[account];
  }

  function feePaidFor(address account) external view returns (uint) {
    return hasPaidFee[account];
  }

  function publishVerification(
    uint256 expiration,
    bytes32 countryAndDocNumberHash,
    bytes calldata signature
  ) external {
    // Signing server will only provide signature if fee has been paid,
    //  not necessary to require it here
    delete hasPaidFee[msg.sender];
    // Recreate hash as built by the client
    bytes32 hash = keccak256(abi.encode(msg.sender, expiration, countryAndDocNumberHash));
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
    bytes32 ethSignedHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    address sigAddr = ecrecover(ethSignedHash, v, r, s);
    require(sigAddr == signer, "Invalid Signature");

    // Revoke verification for any other account that uses
    //  the same document number/country
    //  e.g. for case of stolen keys
    if(idHashToAccount[countryAndDocNumberHash] != address(0x0)) {
      _revokeVerification(idHashToAccount[countryAndDocNumberHash]);
    }
    // Update account state
    idHashToAccount[countryAndDocNumberHash] = msg.sender;
    accounts[msg.sender] = VerifiedPassport(expiration, countryAndDocNumberHash);
    emit VerificationUpdated(msg.sender, expiration);
  }

  function revokeVerification() external {
    require(accounts[msg.sender].expiration > 0, "Account not verified");
    _revokeVerification(msg.sender);
  }

  function revokeVerificationOf(address account) external onlyOwner {
    require(accounts[account].expiration > 0, "Account not verified");
    _revokeVerification(account);
  }

  function _revokeVerification(address account) internal {
    // Do not need to delete from idHashToAccount since that data is
    //  not used for determining account status
    delete accounts[account];
    // Revoking the verification also redacts the personal data
    delete personalData[account];
    emit VerificationUpdated(account, 0);
  }

  function addressActive(address toCheck) public view returns (bool) {
    return accounts[toCheck].expiration > block.timestamp;
  }

  function addressExpiration(address toCheck) external view returns (uint) {
    return accounts[toCheck].expiration;
  }

  function addressIdHash(address toCheck) external view returns(bytes32) {
    return accounts[toCheck].countryAndDocNumberHash;
  }

  function publishPersonalData(
    bool over18,
    bytes calldata over18Signature,
    bool over21,
    bytes calldata over21Signature,
    uint countryCode,
    bytes calldata countrySignature
  ) external {
    require(addressActive(msg.sender), "Account must be active");
    if(over18Signature.length == 65) {
      bytes32 hash = keccak256(abi.encode(msg.sender, over18 ? "over18" : "notOver18"));
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(over18Signature);
      bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

      address sigAddr = ecrecover(ethSignedHash, v, r, s);
      require(sigAddr == signer, "Invalid Signature");
      personalData[msg.sender].over18 = over18;
      if(over18) {
        emit IsOver18(msg.sender);
      }
    }
    if(over21Signature.length == 65) {
      bytes32 hash = keccak256(abi.encode(msg.sender, over21 ? "over21" : "notOver21"));
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(over21Signature);
      bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

      address sigAddr = ecrecover(ethSignedHash, v, r, s);
      require(sigAddr == signer, "Invalid Signature");
      personalData[msg.sender].over21 = over21;
      if(over21) {
        emit IsOver21(msg.sender);
      }
    }
    if(countrySignature.length == 65) {
      bytes32 hash = keccak256(abi.encode(msg.sender, countryCode));
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(countrySignature);
      bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

      address sigAddr = ecrecover(ethSignedHash, v, r, s);
      require(sigAddr == signer, "Invalid Signature");
      personalData[msg.sender].countryCode = countryCode;
      emit CountryOfOrigin(msg.sender, countryCode);
    }
  }

  function redactPersonalData() external {
    delete personalData[msg.sender];
  }

  function isOver18(address toCheck) external view returns (bool) {
    return personalData[toCheck].over18;
  }

  function isOver21(address toCheck) external view returns (bool) {
    return personalData[toCheck].over21;
  }

  function getCountryCode(address toCheck) external view returns (uint) {
    return personalData[toCheck].countryCode;
  }

  function setSigner(address newSigner) external onlyOwner {
    require(newSigner != address(0), "Signer cannot be zero address");
    signer = newSigner;
  }

  function setFeeToken(address newFeeToken) external onlyOwner {
    require(newFeeToken != address(0), "Fee Token cannot be zero address");
    address oldFeeToken = address(feeToken);
    feeToken = IERC20(newFeeToken);
    emit FeeTokenChanged(oldFeeToken, newFeeToken);
  }

  function setFeeAmount(uint newFeeAmount) external onlyOwner {
    uint oldFeeAmount = feeAmount;
    feeAmount = newFeeAmount;
    emit FeeAmountChanged(oldFeeAmount, newFeeAmount);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function transferFeeToken(address recipient, uint amount) external onlyOwner {
    bool sent = feeToken.transfer(recipient, amount);
    require(sent, "Fee transfer failed");
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  // From https://solidity-by-example.org/signature/
  function splitSignature(bytes memory sig) internal pure
    returns (bytes32 r, bytes32 s, uint8 v)
  {
    require(sig.length == 65, "invalid signature length");
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  }

}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}