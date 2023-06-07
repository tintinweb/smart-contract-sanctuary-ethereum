pragma solidity ^0.8.0;

contract CircleManagement {
  mapping(address => string) public referralCode;
  mapping(string => address) public referralCodeOwner;

  // mapping(address => address) public circleInviterTier; // TODO: Is the hiearchy needed in the contract level?
  mapping(address => mapping(address => bool)) public joinedCircle;
  mapping(address => address[]) public circle;

  event GeneratedReferralCode(address indexed wallet, string referralCode);
  event JoinedCircle(address indexed inviter, address invitee, string referralCode);

  event WhoIsSigner(address signer);

  function generateReferralCode(
    address inviter,
    string memory generatedReferralCode,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 hash = keccak256(abi.encodePacked(inviter, generatedReferralCode));
    address recoveredInviter = recoverSigner(hash, v, r, s);

    if (recoveredInviter != inviter) {
      emit WhoIsSigner(recoveredInviter);
      emit WhoIsSigner(inviter);
      revert("Invalid signature");
    }

    if (bytes(referralCode[inviter]).length > 0) {
      revert("Referral code already generated");
    }

    referralCode[inviter] = generatedReferralCode;
    referralCodeOwner[generatedReferralCode] = inviter;

    emit GeneratedReferralCode(inviter, generatedReferralCode);
  }

  function joinCircle(
    string memory appliedReferralCode,
    address invitee,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    address inviter = referralCodeOwner[appliedReferralCode];
    if (inviter == address(0)) {
      revert("Invalid referral code");
    }

    bytes32 hash = keccak256(abi.encodePacked(appliedReferralCode, invitee));
    address recoveredInvitee = recoverSigner(hash, v, r, s);
    if (recoveredInvitee != invitee) {
      revert("Invalid signature");
    }

    if (joinedCircle[inviter][recoveredInvitee] == true) {
      revert("Already joined");
    }

    joinedCircle[inviter][recoveredInvitee] = true;
    circle[inviter].push(recoveredInvitee);

    emit JoinedCircle(inviter, recoveredInvitee, appliedReferralCode);
  }

  function recoverSigner(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    return ecrecover(prefixedHash, v, r, s);
  }
}