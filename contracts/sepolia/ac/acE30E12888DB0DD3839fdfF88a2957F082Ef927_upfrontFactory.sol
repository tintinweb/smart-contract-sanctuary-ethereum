/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

/*
   __  __      ____                 __ 
  / / / /___  / __/________  ____  / /_
 / / / / __ \/ /_/ ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ /  / /_/ / / / / /_  
\____/ .___/_/ /_/   \____/_/ /_/\__/  
    /_/                                

  Factory Contract

  Authors: <MagicFormulaY> and <dotfx>
  Date: 2023/06/06
  Version: 1.0.0
*/

pragma solidity >=0.8.18 <0.9.0;

library String {
  function compare(string memory str1, string memory str2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}

library Address {
  function isContract(address implementation) internal view returns (bool) {
    return implementation.code.length > 0;
  }
}

library Clones {
  function predictDeterministicAddress(bytes memory bytecode, bytes32 salt) internal view returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

    return address(uint160(uint256(hash)));
  }

  function cloneDeterministic(bytes memory bytecode, bytes32 salt) internal returns (address result) {
    assembly {
      result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }

    require(result != address(0), "Deploy failed");
  }
}

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

  modifier isOwner() virtual {
    require(_msgSender() == _owner, "Caller must be the owner.");

    _;
  }

  function renounceOwnership() external virtual isOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");

    locked = true;
    _;
    locked = false;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface upfrontMultiSignatureWallet {
  function listManagers(bool) external view returns (address[] memory);
}

interface ICustomizable {
  function initialize(address owner, bytes calldata data) external;
}

contract upfrontFactory is ReentrancyGuard {
  string public constant VERSION = "1.0.0";
  address private MULTISIGN_ADDRESS;
  address private EXECUTOR_ADDRESS;
  address private TREASURY_ADDRESS;
  uint256 private DISCOUNT_MIN;
  uint256 private DISCOUNT_PCT;
  uint256 private PRICE_MULTITRANSFER;
  uint256 private PRICE_MULTITRANSFER_PER_WALLET;
  bool private initialized;

  struct templateDataStruct {
    bool exists;
    bool active;
    uint256 price;
    bool discountable;
  }

  struct templateReturnStruct {
    uint256 id;
    bool discountable;
    uint256 price;
    uint256 amount;
  }

  struct userDataStruct {
    bool exists;
    uint256 balance;
    mapping(bytes32 => deployDataStruct) deploy;
    bytes32[] deployList;
    addedCreditDataStruct[] addedCredit;
  }

  struct deployDataStruct {
    bool exists;
    uint256 templateId;
    uint256 paidTimestamp;
    uint256 deployTimestamp;
    uint256 refundTimestamp;
    uint256 amount;
    uint256 gas;
    address contractAddress;
  }

  struct addedCreditDataStruct {
    uint256 timestamp;
    uint256 amount;
    address executor;
  }

  struct userReturnStruct {
    uint256 balance;
    deployReturnStruct[] deploy;
    addedCreditDataStruct[] addedCredit;
  }

  struct deployReturnStruct {
    bytes32 receipt;
    uint256 templateId;
    uint256 paidTimestamp;
    uint256 deployTimestamp;
    uint256 refundTimestamp;
    uint256 amount;
    uint256 gas;
    address contractAddress;
  }

  struct pendingDeployReturnStruct {
    address user;
    bytes32 receipt;
    uint256 templateId;
    uint256 gas;
  }

  uint256[] private templateList;
  mapping(uint256 => templateDataStruct) private templateData;

  address[] private userList;
  mapping(address => userDataStruct) private userData;

  event Deposit(address indexed from, uint256 amount);
  event WithdrawnNativeFunds(address indexed to, uint256 amount, address executor);
  event templatePaid(address indexed user, uint256 indexed templateId, uint256 amount, uint256 gas, bytes32 receipt);
  event templateDeployed(address indexed user, uint256 indexed templateId, bytes32 receipt, address contractAddress);
  event templateRefund(address indexed user, uint256 indexed templateId, bytes32 receipt);
  event addedCredit(address indexed user, uint256 amount);
  event bulkAddedCredit(address[] users, uint256 amount, address executor);

  modifier isOwner() override {
    require(_msgSender() == owner() || (MULTISIGN_ADDRESS != address(0) && _msgSender() == MULTISIGN_ADDRESS), "Factory: Caller must be the owner or the Multi-Signature Wallet.");

    _;
  }

  modifier isManager() {
    require(MULTISIGN_ADDRESS != address(0));

    address[] memory managers = upfrontMultiSignatureWallet(MULTISIGN_ADDRESS).listManagers(true);

    uint256 cnt = managers.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (managers[i] != _msgSender()) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Caller must be manager.");

    _;
  }

  modifier isExecutor() {
    require(_msgSender() == EXECUTOR_ADDRESS, "Caller must be executor.");

    _;
  }

  modifier isInitialized() {
    require(initialized, "Factory: Contract not initialized.");

    _;
  }

  modifier isTemplate(uint256 templateId, bool active) {
    require(templateData[templateId].exists, "Factory: Unknown template id.");

    if (active) { require(templateData[templateId].active, "Factory: Unknown template id."); }

    _;
  }

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function getDiscountInfo() external view returns (uint256, uint256) {
    return (DISCOUNT_MIN, DISCOUNT_PCT);
  }

  function getMultiTransferPrice() external view returns (uint256, uint256) {
    return (PRICE_MULTITRANSFER, PRICE_MULTITRANSFER_PER_WALLET);
  }

  function setMultiTransferPrice(uint256 _price, uint256 _pricePerWallet) external isOwner isInitialized {
    PRICE_MULTITRANSFER = _price;
    PRICE_MULTITRANSFER_PER_WALLET = _pricePerWallet;
  }

  function setTemplate(uint256 templateId, bool active, uint256 price, bool discountable) external isOwner isInitialized {
    if (!templateData[templateId].exists) {
      templateData[templateId].exists = true;
      templateList.push(templateId);
    }

    templateData[templateId].active = active;
    templateData[templateId].price = price;
    templateData[templateId].discountable = discountable;
  }

  function _addUser(address _addr) internal {
    userList.push(_addr);
    userData[_addr].exists = true;
  }

  function addCredit() public payable isInitialized nonReEntrant {
    require(msg.value > 0);

    if (!userData[msg.sender].exists) { _addUser(msg.sender); }

    unchecked {
      userData[msg.sender].balance += msg.value;
      userData[msg.sender].addedCredit.push(addedCreditDataStruct(getCurrentTime(), msg.value, msg.sender));

      emit addedCredit(msg.sender, msg.value);
    }
  }

  function adminBulkAddCredit(address[] memory users, uint256 amount) external isInitialized isManager {
    _bulkAddCredit(users, amount, msg.sender);
  }

  function execBulkAddCredit(address[] memory users, uint256 amount) external isInitialized isExecutor {
    _bulkAddCredit(users, amount, msg.sender);
  }

  function _bulkAddCredit(address[] memory users, uint256 amount, address executor) internal {
    require(amount > 0);

    uint256 cnt = users.length;

    unchecked {
      for (uint256 u; u < cnt; u++) {
        if (!userData[users[u]].exists) { _addUser(users[u]); }

        userData[users[u]].balance += amount;
        userData[users[u]].addedCredit.push(addedCreditDataStruct(getCurrentTime(), amount, address(this)));
      }
    }

    emit bulkAddedCredit(users, amount, executor);
  }

  function tokenMultiTransfer(address token, address[] memory target, uint256[] memory amount) public payable isInitialized nonReEntrant {
    uint256 cnt = amount.length;

    require(cnt > 0);
    require(target.length == cnt, "Factory: Invalid number of params.");

    if (!userData[msg.sender].exists) { _addUser(msg.sender); }

    IERC20 iface = IERC20(token);

    unchecked {
      uint256 price = PRICE_MULTITRANSFER + (cnt * PRICE_MULTITRANSFER_PER_WALLET);
      uint256 total;

      if (msg.value != price) {
        if (msg.value > price) { revert("Factory: Amount transferred exceeds required price."); }
        if (userData[msg.sender].balance + msg.value < price) { revert("Factory: Insufficient balance."); }
      }

      for (uint256 a; a < cnt; a++) { total += amount[a]; }

      require(iface.balanceOf(msg.sender) >= total, "Factory: Insufficient balance.");
      require(iface.allowance(msg.sender, address(this)) >= total, "Factory: Insufficient allowance.");
    }

    if (msg.value > 0 && TREASURY_ADDRESS != address(0)) {
      (bool success, bytes memory result) = payable(TREASURY_ADDRESS).call{ value: msg.value }("");

      if (!success) {
        if (result.length > 0) {
          assembly {
            let size := mload(result)

            revert(add(32, result), size)
          }
        }

        revert("Function call reverted.");
      }
    }

    unchecked {
      for (uint256 a; a < cnt; a++) {
        bool success = iface.transferFrom(msg.sender, target[a], amount[a]);

        require(success, "Transfer error.");
      }
    }
  }

  function payTemplate(uint256 templateId, uint256 gas, bytes32 nonce) public payable isTemplate(templateId, true) isInitialized nonReEntrant returns (bytes32 receipt) {
    require(gas > 0);

    if (!userData[msg.sender].exists) { _addUser(msg.sender); }

    uint256 price = templateData[templateId].price;
    uint256 amount;

    if (templateData[templateId].discountable) {
      if (userData[msg.sender].balance >= DISCOUNT_MIN) { price -= templateData[templateId].price * DISCOUNT_PCT / (100*100); }
    }

    unchecked {
      amount = msg.value - gas;

      if (amount != price) {
        if (amount > price) {
          uint256 dif = amount - price;

          amount -= dif;
          gas += dif;
        }

        if (amount < price && userData[msg.sender].balance + amount < price) { revert("Factory: Insufficient balance."); }
      }
    }

    if (amount > 0 && TREASURY_ADDRESS != address(0)) {
      (bool success, bytes memory result) = payable(TREASURY_ADDRESS).call{ value: amount }("");

      if (!success) {
        if (result.length > 0) {
          assembly {
            let size := mload(result)

            revert(add(32, result), size)
          }
        }

        revert("Function call reverted.");
      }
    }

    if (gas > 0 && EXECUTOR_ADDRESS != address(0)) {
      (bool success, bytes memory result) = payable(EXECUTOR_ADDRESS).call{ value: gas }("");

      if (!success) {
        if (result.length > 0) {
          assembly {
            let size := mload(result)

            revert(add(32, result), size)
          }
        }

        revert("Function call reverted.");
      }
    }

    receipt = keccak256(abi.encodePacked(templateId, getCurrentTime(), nonce, msg.sender));

    unchecked {
      if (userData[msg.sender].balance > 0) { userData[msg.sender].balance -= price - amount; }
    }

    userData[msg.sender].deployList.push(receipt);
    userData[msg.sender].deploy[receipt] = deployDataStruct(true, templateId, getCurrentTime(), 0, 0, price, gas, address(0));

    emit templatePaid(msg.sender, templateId, price, gas, receipt);
  }

  function adminCancelDeployTemplate(address user, bytes32 receipt, bool refund) external isInitialized isManager {
    require(userData[user].exists, "Unknown user.");
    require(userData[user].deploy[receipt].exists, "Unknown receipt.");
    require(userData[user].deploy[receipt].contractAddress == address(0), "Template already deployed.");

    uint256 templateId = userData[user].deploy[receipt].templateId;

    if (refund) {
      uint256 amount = userData[user].deploy[receipt].amount;

      /*
      require(getBalance() >= amount, "Insufficient balance.");

      (bool success, bytes memory result) = payable(user).call{ value: amount }("");

      if (!success) {
        if (result.length > 0) {
          assembly {
            let size := mload(result)

            revert(add(32, result), size)
          }
        }

        revert("Function call reverted.");
      }
      */

      unchecked {
        userData[user].balance += amount;
        userData[user].deploy[receipt].refundTimestamp = getCurrentTime();
      }

      emit templateRefund(user, templateId, receipt);
    }

    userData[user].deploy[receipt].contractAddress = 0x000000000000000000000000000000000000dEaD;
  }

  function adminDeployTemplate(address user, bytes32 receipt, bytes memory bytecode, address owner, bytes calldata data) external isInitialized isManager nonReEntrant returns (address) {
    return _deployTemplate(user, receipt, bytecode, owner, data);
  }

  function execDeployTemplate(address user, bytes32 receipt, bytes memory bytecode, address owner, bytes calldata data) external isInitialized isExecutor nonReEntrant returns (address) {
    return _deployTemplate(user, receipt, bytecode, owner, data);
  }

  function _deployTemplate(address user, bytes32 receipt, bytes memory bytecode, address owner, bytes calldata data) internal returns (address) {
    require(userData[user].exists, "Unknown user.");
    require(userData[user].deploy[receipt].exists, "Unknown receipt.");
    require(userData[user].deploy[receipt].contractAddress == address(0), "Template already deployed.");

    unchecked {
      address predictAddress = Clones.predictDeterministicAddress(bytecode, receipt);

      require(!Address.isContract(predictAddress),"Factory: Contract already exists.");

      address contractAddress = Clones.cloneDeterministic(bytecode, receipt);

      require(predictAddress == contractAddress, "Factory: Deployed address is not the predicted address.");

      emit templateDeployed(user, userData[user].deploy[receipt].templateId, receipt, contractAddress);

      userData[user].deploy[receipt].deployTimestamp = getCurrentTime();
      userData[user].deploy[receipt].contractAddress = contractAddress;

      ICustomizable(contractAddress).initialize(owner, data);

      return contractAddress;
    }
  }

  function listTemplates(bool _active) external view returns (templateReturnStruct[] memory) {
    uint256 cnt = templateList.length;
    uint256 len = _active ? _countActiveTemplates() : cnt;
    uint256 i;

    templateReturnStruct[] memory data = new templateReturnStruct[](len);

    unchecked {
      for (uint256 t; t < cnt; t++) {
        if (_active && !templateData[templateList[t]].active) { continue; }

        uint256 price = templateData[templateList[t]].price;

        if (templateData[templateList[t]].discountable && userData[msg.sender].exists) {
          if (userData[msg.sender].balance >= DISCOUNT_MIN) { price -= templateData[templateList[t]].price * DISCOUNT_PCT / (100*100); }
        }

        data[i++] = templateReturnStruct(templateList[t], templateData[templateList[t]].discountable, templateData[templateList[t]].price, price);
      }
    }

    return data;
  }

  function _countPendingDeploys() internal view returns (uint256) {
    uint256 cnt = userList.length;
    uint256 pending;

    unchecked {
      for (uint256 u; u < cnt; u++) {
        uint256 dcnt = userData[userList[u]].deployList.length;

        if (dcnt == 0) { continue; }

        for (uint256 d; d < dcnt; d++) {
          bytes32 receipt =  userData[userList[u]].deployList[d];

          if (userData[userList[u]].deploy[receipt].contractAddress != address(0)) { continue; }

          pending++;
        }
      }
    }

    return pending;
  }

  function _countActiveTemplates() internal view returns (uint256) {
    uint256 cnt = templateList.length;
    uint256 active;

    unchecked {
      for (uint256 t; t < cnt; t++) {
        if (!templateData[templateList[t]].active) { continue; }

        active++;
      }
    }

    return active;
  }

  function adminListPendingDeploys() external view isManager returns (pendingDeployReturnStruct[] memory) {
    return _listPendingDeploys();
  }

  function execListPendingDeploys() external view isExecutor returns (pendingDeployReturnStruct[] memory) {
    return _listPendingDeploys();
  }

  function _listPendingDeploys() internal view returns (pendingDeployReturnStruct[] memory) {
    uint256 cnt = userList.length;
    uint256 pcnt = _countPendingDeploys();
    uint256 i;

    pendingDeployReturnStruct[] memory data = new pendingDeployReturnStruct[](pcnt);

    unchecked {
      for (uint256 u; u < cnt; u++) {
        uint256 dcnt = userData[userList[u]].deployList.length;

        if (dcnt == 0) { continue; }

        for (uint256 d; d < dcnt; d++) {
          bytes32 receipt = userData[userList[u]].deployList[d];
          deployDataStruct memory deploy = userData[userList[u]].deploy[receipt];

          if (deploy.contractAddress != address(0)) { continue; }

          data[i++] = pendingDeployReturnStruct(userList[u], receipt, deploy.templateId, deploy.gas);
        }
      }
    }

    return data;
  }

  function listUsers() external view returns (address[] memory) {
    uint256 cnt = userList.length;
    uint256 i;

    address[] memory data = new address[](cnt);

    unchecked {
      for (uint256 u; u < cnt; u++) { data[i++] = userList[u]; }
    }

    return data;
  }

  function getUserInfo(address _user) external view returns (userReturnStruct memory user) {
    require(userData[_user].exists, "Unknown user.");

    uint256 cnt = userData[_user].deployList.length;

    user.balance = userData[_user].balance;
    user.deploy = new deployReturnStruct[](cnt);
    user.addedCredit = userData[_user].addedCredit;

    unchecked {
      for (uint256 d; d < cnt; d++) {
        bytes32 receipt = userData[_user].deployList[d];
        deployDataStruct memory deploy = userData[_user].deploy[receipt];

        user.deploy[d] = deployReturnStruct(receipt, deploy.templateId, deploy.paidTimestamp, deploy.deployTimestamp, deploy.refundTimestamp, deploy.amount, deploy.gas, deploy.contractAddress);
      }
    }

    return user;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function withdrawNativeFunds(address payable _to, uint256 _amount) external payable isOwner isInitialized nonReEntrant {
    require(_amount > 0);
    require(getBalance() >= _amount, "Insufficient balance.");

    (bool success, bytes memory result) = _to.call{ value: _amount }("");

    if (!success) {
      if (result.length > 0) {
        assembly {
          let size := mload(result)

          revert(add(32, result), size)
        }
      }

      revert("Function call reverted.");
    }

    emit WithdrawnNativeFunds(_to, _amount, msg.sender);
  }

  function setTreasury(address _address) external isOwner isInitialized {
    require(_address != address(0));

    TREASURY_ADDRESS = _address;
  }

  function setDiscount(uint256 _min, uint256 _pct) external isOwner isInitialized {
    require(_pct < 100*100);

    DISCOUNT_MIN = _min;
    DISCOUNT_PCT = _pct;
  }

  function setMultiSignatureWallet(address _address) external isOwner isInitialized {
    require(_address != address(0));

    MULTISIGN_ADDRESS = _address;
  }

  function setExecutor(address _address) external isOwner isInitialized {
    require(_address != address(0));

    EXECUTOR_ADDRESS = _address;
  }

  function initialize() public {
    require(!initialized, "Contract already initialized.");

    _setOwner(_msgSender());

    initialized = true;
  }

  receive() external payable {
    addCredit();
  }

  fallback() external payable {
    require(msg.data.length == 0);

    emit Deposit(msg.sender, msg.value);
  }

  constructor() {
    initialize();
  }

  uint256[50] private __void; // empty reserved space to allow future versions to add new variables without shifting down storage in the inheritance chain.
}