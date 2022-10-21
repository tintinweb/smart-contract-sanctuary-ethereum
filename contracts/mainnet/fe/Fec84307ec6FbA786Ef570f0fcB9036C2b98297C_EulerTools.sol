// SPDX-License-Identifier: MIT
//                       ...`
//                   :sdmdhhdNy.
//                .sNh/.   `ydyM+
//              .sNy.     /m+  sM-
//         .+ymmhyN:    `hh.   .My                        .:-                                           .-.
//       +dmsydy+.-mo  /m+     `MMmo`                     oMM                  -hh`                     yMy
//     .mm:    `/shdMhhh.      -Mo-hN:    .+sso-  +o:  ++ oMM  :oss+.  oo/ss   :yMMo  /sys/      /sys/  yMy `/ss+-
//     mm`         `:NMmhyo/.  yM.  hM`   +Mm  Mh NMo  mM oMM +Mm   Mh MMNso   :hMMs -NMy+sMN- -NMy+sMN yMy NM
//     Nm           .Mom+`-/oydMo   yM.  NMdyyyMM NMo  mM oMM MMyssdMN MM/     :MM` yMd   dMh yMd   dMh oyz smNyo:
//     :Nh.         +N `dy`  .Nh  `sM+   dMh      My .NMs MM- dMh      MM:     :MM-  oMN. .NM  oMN. .NM yMy    dMy
//      `sNh+.      ds   sm--Nh./yNy-    `yNNmMmo /NMNNNM oMN :dMmmMh: MM- /Nd `yNM  omMNMmo   omMNMmo  sNs ymmmNd:
//         +MNmhso//M+---:yMMMNmy/`
//          mm`.:/ossyyyyNMm/-`
//          -Nh.      .omm/
//           .sNdssshmds-
//              .:::-`

pragma solidity ^0.8.7;

import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EulerToolsStorage.sol";
import "./ERC20Standard.sol";
import "./SafeETH.sol";


contract EulerTools is EulerToolsStorage, ERC20Standard {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  function init(address globalStorage, address creator, uint256 maxSupply, address oldToken) external virtual initializer {
    __ERC20Standard_init('Euler Tools', 'EULER', globalStorage);
    _grantRole(DEFAULT_ADMIN_ROLE, creator);
    _maxSupply = maxSupply * (10 ** uint256(decimals()));
    _oldToken = oldToken;
  }

  function addAllowedToken(uint256 chainId, address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    allowedTokens[chainId] = token;
    emit AddAllowedToken(chainId, token);
  }

  function migrate(uint256 amount) external whenNotPaused {
    require(_oldToken != address(0), 'OLD_TOKEN_ZERO');
    require(_maxSupply >= (amount + totalSupply()), 'MAX_SUPPLY_EXCEEDED');
    require(IERC20Upgradeable(_oldToken).balanceOf(address(msg.sender)) >= amount, 'BALANCE_EXCEEDED');

    migratedTokens[msg.sender] += amount;
    _mint(msg.sender, amount);
    IERC20Upgradeable(_oldToken).safeTransferFrom(msg.sender, address(this), amount);

    emit Migration(msg.sender, amount);
  }

  function bridgeIn(uint256 chainIdDestination, address tokenDestination, uint256 amount)
  external payable requireTax(EulerTools.bridgeIn.selector, 0) whenNotPaused {
    require(allowedTokens[chainIdDestination] == tokenDestination, 'INCORRECT_TOKEN_DEST');
    _burn(msg.sender, amount);
    emit Bridge(msg.sender, amount, block.chainid, chainIdDestination, tokenDestination);
  }

  function bridgeOut(BridgeTicket memory ticket, Signature memory signature)
  external payable requireTax(EulerTools.bridgeOut.selector, 0) whenNotPaused {
    bytes32 _bridgeHash = ticketHash(ticket);
    _checkSignature(_bridgeHash, signature);
    require(msg.sender == ticket.account, 'INCORRECT_ACCOUNT');
    _checkBridgeOut(ticket);
    _mint(ticket.account, ticket.amount);
    emit ClaimBridge(ticket.account, ticket.amount, ticket.chainIdOrigin,
      ticket.chainIdDestination, ticket.transactionOrigin, ticket.logIndexOrigin, ticket.tokenOrigin);
  }

  function bridgeOutMinter(BridgeTicket memory ticket, Signature memory signature)
  external onlyRole(MINTER_ROLE) whenNotPaused {
    bytes32 _bridgeHash = ticketHash(ticket);
    _checkSignature(_bridgeHash, signature);
    _checkBridgeOut(ticket);
    _mint(ticket.account, ticket.amount);
    emit ClaimBridge(ticket.account, ticket.amount, ticket.chainIdOrigin,
      ticket.chainIdDestination, ticket.transactionOrigin, ticket.logIndexOrigin, ticket.tokenOrigin);
  }

  function ticketHash(BridgeTicket memory ticket) public pure returns(bytes32 _hash) {
    _hash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0),
        ticket.chainIdOrigin, ticket.transactionOrigin, ticket.logIndexOrigin, ticket.chainIdDestination,
        ticket.tokenOrigin, ticket.tokenDestination, ticket.amount, ticket.account));
  }

  function _checkSignature(bytes32 _hash, Signature memory signature) internal view {
      address account = ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(signature.value),
          signature.v, signature.r, signature.s);

      require(_hash == signature.value && hasRole(MINTER_ROLE, account), string(
          abi.encodePacked('Malformed signature ',
          StringsUpgradeable.toHexString(uint256(signature.value), 32),
          ' ',
          StringsUpgradeable.toHexString(uint160(account), 20)))
      );
  }

  function _checkBridgeOut(BridgeTicket memory ticket) internal {
    bytes32 _hash = keccak256(abi.encodePacked(ticket.chainIdOrigin, ticket.transactionOrigin, ticket.logIndexOrigin));
    require(ticket.chainIdDestination == block.chainid, 'INCORRECT_CHAIN');
    require(!ticketsUsed[_hash], 'TICKET_ALREADY_USED');
    require(_maxSupply >= (ticket.amount + totalSupply()), 'MAX_SUPPLY_EXCEEDED');
    require(allowedTokens[ticket.chainIdOrigin] == ticket.tokenOrigin, 'INCORRECT_TOKEN_ORIGIN');
    require(_this == ticket.tokenDestination, 'INCORRECT_TOKEN_DEST');
    ticketsUsed[_hash] = true;
  }
}