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

pragma solidity 0.8.7;

import "./IERC165.sol";
import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";
import "./ICheckRoleProxy.sol";

contract ERC1967ProxyUpgradeable is Proxy {

  bytes32 private constant _IMPL_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
  bytes32 private constant _IS_ALIAS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.alias")) - 1);

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  event Upgraded(address indexed implementation);

  modifier onlyRole(bytes32 _role) {
    ICheckRoleProxy(address(this)).checkRole(_role, msg.sender);
    _;
  }

  function __ERC1967ProxyUpgradeable_init(address implementation_) external {
    require(StorageSlot.getAddressSlot(_IMPL_SLOT).value == address(0), "ERC1967: contract is already initialized");
    _setImplementation(implementation_);
  }

  function setImplementation(address implementation_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setImplementation(implementation_);
  }

  function getImplementation() public view returns (address) {
    return _implementation();
  }

  function _setImplementation(address implementation_) internal {
    require(Address.isContract(implementation_), "ERC1967: new implementation is not a contract");
    require(IERC165(implementation_).supportsInterface(type(ICheckRoleProxy).interfaceId), "ERC1967: not support check role");

    StorageSlot.getAddressSlot(_IMPL_SLOT).value = implementation_;
    emit Upgraded(implementation_);
  }

  function _implementation() internal view virtual override returns (address implementation) {
    implementation = StorageSlot.getAddressSlot(_IMPL_SLOT).value;
  }
}