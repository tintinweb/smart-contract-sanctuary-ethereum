pragma solidity ^0.8.9;

//importazione di tutti i contratti relativi a un possibile ruolo di un'organizzazione
import './ProducerRole.sol';
import './RegulatoryDepartmentRole.sol';

contract SupplyChain is ProducerRole, RegulatoryDepartmentRole{
    //mappa che a un identificatore associa un prodotto
    mapping (uint => Product) products;
    
    //stati disponibili
    enum State{
        Produced,
        Pending,
        Refused,
        Unblocked,
        Blocked
    }

    //dichiarazione dell'oggetto Product
    struct Product{
        uint upc;
        string name;
        State productState;
        address currentBlockerOrgId;
        address approverOrgId;
        address issuerOrgId;
    }

    //i seguenti modificatori controllano che l'oggetto sul quale viene svolta un'azione
    //abbia passato gli step precedenti della supplyChain 
    modifier produced(uint _upc){
        require(products[_upc].productState == State.Produced);
        _;
    }

    modifier pending(uint _upc){
        require(products[_upc].productState == State.Pending);
        _;
    }

    modifier unblocked(uint _upc){
        require(products[_upc].productState == State.Unblocked);
        _;
    }

    modifier blocked(uint _upc){
        require(products[_upc].productState == State.Blocked);
        _;
    }

    //addProduct ha il compito di creare un Generic e aggiungerlo alla mappa.
    function addProduct(uint _upc, string memory _name) public onlyProducer(){
        address _currentBlockerOrgId;
        address _approverOrgId;
        Product memory newProduct;
        newProduct.upc = _upc;
        newProduct.name = _name;
        newProduct.productState = State.Produced;
        newProduct.currentBlockerOrgId = _currentBlockerOrgId;
        newProduct.approverOrgId = _approverOrgId;
        newProduct.issuerOrgId = msg.sender;

        products[_upc] = newProduct;
    }

    //chiede la registrazione di un prodotto
    function requestProductRegistration(uint _upc) public onlyProducer() produced(_upc){
        products[_upc].productState = State.Pending;
    }

    //accetta la registrazione di un prodotto
    function acceptProductRegistration(uint _upc) public onlyDepartment() pending(_upc){
        products[_upc].productState = State.Unblocked;
    }

    //rifiuta la registrazione di un prodotto
    function refuseProductRegistration(uint _upc) public onlyDepartment() pending(_upc){
        products[_upc].productState = State.Refused;
    }

    //
    function blockProduct(uint _upc) public onlyDepartment() unblocked(_upc){
        products[_upc].productState = State.Blocked;
    }

    function unblockProduct(uint _upc) public onlyDepartment() blocked(_upc){
        products[_upc].productState = State.Unblocked;
    }
}

pragma solidity ^0.8.9;

import "./Roles.sol";

contract ProducerRole{
    using Roles for Roles.Role;
    Roles.Role private producers;

    constructor() public{
        _addProducer(msg.sender);
    }

    modifier onlyProducer(){
        require(isProducer(msg.sender));
        _;
    }

    function isProducer(address account) public view returns(bool){
        return producers.has(account);
    }

    function addProducer(address account) public{
        _addProducer(account);
    }

    function renounceProducer(address account) public{
        _removeProducer(account);
    }

    function _addProducer(address account) internal {
        producers.add(account);
    }

    function _removeProducer(address account) internal {
        producers.remove(account);
    }
}

pragma solidity ^0.8.9;

import "./Roles.sol";

contract RegulatoryDepartmentRole{
    using Roles for Roles.Role;
    Roles.Role private departments;

    constructor() public {
        _addDepartment(msg.sender);
    }

    modifier onlyDepartment(){
        require(isDepartment(msg.sender));
        _;
    }

    function isDepartment(address account) public view returns(bool){
        return departments.has(account);
    }

    function addDepartment(address account) public{
        _addDepartment(account);
    }

    function removeDepartment(address account) public{
        _removeDepartment(account);
    }

    function _addDepartment(address account) internal {
        departments.add(account);
    }

    function _removeDepartment(address account) internal {
        departments.remove(account);
    }
}

pragma solidity ^0.8.9;

library Roles{
    struct Role{
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal{
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal{
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool){
        require(account != address(0));
        return role.bearer[account];
    }
}