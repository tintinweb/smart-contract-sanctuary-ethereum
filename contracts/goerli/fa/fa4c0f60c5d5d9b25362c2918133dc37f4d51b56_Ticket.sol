/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: UNLICENSED;

pragma solidity ^0.8.7;


contract Ticket{


    mapping(address => uint256) private _basicTicketBalances;
    mapping(address=> uint256) private _ethContractBalances;
    mapping(address => uint256) private _vipTicketBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address=>uint256) insurance;
    mapping(address=>uint256) vipInsurance;


    address private Owner;

    constructor(uint _setBasicTicketSupply, uint _setVipSupply, uint _marketingTicket, string memory _setName, string memory _setSymbol, string memory _setLocation, string memory _setDay, string memory _setMonth, string memory _setYear) {
        Owner = msg.sender; // le propiétaire du contract et celui qui déploie le contract;
        _basicTicketBalances[msg.sender] = _marketingTicket; // mint la quantité désiré de ticket destiné au marketing sur le wallet du deployeur du contract;
        _maxSupply = (_setBasicTicketSupply + _setVipSupply + _marketingTicket) - _totalSupply; // total des tickets disponible à la vente;
        _vipSupply = _setVipSupply; // definit le nombre de ticket vip disponible a la vente;
        _name = _setName; // definit le nom de contract;
        _symbol = _setSymbol; // definit le symbol du contract;
        _location = _setLocation; // definit le lieu de l'evenement;
        _day = _setDay; // definit le jour de l'evenement;
        _month = _setMonth; // definit le mois de l'evenement;
        _year = _setYear; // definit l'année de l'evenement;

    }

    modifier onlyOwner{
        require (msg.sender == Owner, "Error: You are not the owner !"); // à ajouter sur chaque fonction qui sont destiné à etre appelé seulement par le propriétaire du contract;
        _;
    }

    
    string private _name; 
    string private _symbol;
    string private _location;
    string private _day;
    string private _month;
    string private _year;
    uint256 private _totalSupply = 0 * 10**_decimals; // la total supply initial démarre à O (total supply initial = tout les types de tickets deja vendu);
    uint256 private _maxSupply; // Max supply = Maximum de tickets disponible en incluant tout les types de tickets;
    uint256 private _vipSupply; // nombre de ticket vip en vente; 
    uint256 private _maxBuy = 10 * 10**_decimals; // maximum d'achat de ticket possible par transaction;
    uint256 private _maxWallet = 10 *10**_decimals; // Maximum de détention de tickets possible par wallet;
    uint256 private _cost = 0.001 ether; // Basic ticket price;
    uint256 private _vipCost = 0.002 ether; // VIP ticket price;
    uint256 private _basicInsuranceCostPercent = 3; // Basic insurance percentage;
    uint256 private _vipInsuranceCostPercent = 5; // VIP insurance percentage;
    uint256 private _basicInsuranceCost = _cost * _basicInsuranceCostPercent /100; // Basic insurance price;
    uint256 private _vipInsuranceCost = _vipCost * _vipInsuranceCostPercent / 100; // VIP insurane price;
    uint8 private constant _decimals = 0; // Decimals 
    address private insuranceAdress = 0xCD8c08d6F349CfF6ED90C937930668be0343348F; // address qui recoit les frais d'assurance;



    function name() public view virtual returns (string memory) { 
        return _name; // retourne le nom du contract;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol; // retourne le symbol du contract;
    }

    function getDate() public view virtual returns(string memory, string memory, string memory, string memory, string memory){
        return (_day, "/", _month, "/", _year); // retourne la date de l'evenement;
    }

    function getLocation() public view virtual returns(string memory){
        return _location; // retourne le lieu de l'evenement;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals; // Show the contract decimal;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply; // retourne le total des tickets deja vendu (en incluant tout les types de tickets);
    }

     function maxSupply() public view virtual returns (uint256) {
        return _maxSupply; // retourne le total de tickets en vente (en incluant tout les types des tickets);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _basicTicketBalances[account]; // retourne le nombre de ticket possedé par une address choisie;
    }

     function vipBalanceOf(address account) public view virtual returns (uint256) {
        return _vipTicketBalances[account]; // retourne le nombre de ticket vip possedé par une address choisie;
    }

    function getContractBalance() public view virtual returns (uint256){
        return _ethContractBalances[address(this)]; // retourne la balance du contract en ether;
    }

    function getBasicCost() public view virtual returns (uint256){
        return _cost; // retourne le prix d'un ticket basic;
    }

    function setBasicCost(uint256 _newBasicCost) external onlyOwner virtual{
        _cost = _newBasicCost; // change le prix d'un ticket basic, seulement le owner peut appeler la fonction;
    }

    function getVipCost() public view virtual returns (uint256){
        return _vipCost; // retourne le prix d'un ticket vip;
    }

    function setVipCost(uint256 _newVipCost) external onlyOwner virtual{
        _cost = _newVipCost; // change le prix d'un ticket vip, seulement le owner peut appeler la fonction;
    }

    function setMaxBuy(uint value) external onlyOwner virtual{
        _maxBuy = value; // change le max d'achat possible de ticket par transaction;
    }

    function getMaxBuy() public view virtual returns (uint){
        return _maxBuy; // retourne le max d'achat par transaction;
    }

    function setMaxWallet(uint value) external onlyOwner virtual{
        _maxWallet = value; // change le max de détention de ticket par wallet;
    }

    function getMaxWallet() public view virtual returns (uint){
        return _maxWallet; // retourne le max de détention de ticket possible par wallet;
    }

    function getInsurancePrice() public view virtual returns(uint){
        return _basicInsuranceCost; // retourne le prix de l'assurance pour un ticket basic;
    }

    function getVipInsurancePrice() public view virtual returns(uint){
        return _vipInsuranceCost; // retourne le prix de l'assurance pour un ticket vip;
    }

    function getInsuranceBalance(address account) public view virtual returns(uint){
        return insurance[account]; // retourne le nombre d'assurance pour ticket basic possedé par un wallet choisi;
    }

    function getInsurancePercent() public view virtual returns(uint){
        return _basicInsuranceCostPercent; // retourne le % de frais d'assurance pour un ticket basic;
    }

    function setInsurancePercent(uint256 _newBasicInsuranceCostPercent) external onlyOwner virtual{
        _basicInsuranceCostPercent = _newBasicInsuranceCostPercent;
        // change le % de frais d'assurance pour un ticket basic;
    }

    function getVipInsuranceBalance(address account) public view virtual returns(uint){
        return vipInsurance[account]; // retourne le nombre d'assurance pour ticket vip possedé par un wallet choisi;
    }

      function getVipInsurancePercent() public view virtual returns(uint){
        return _vipInsuranceCostPercent; // retourne le % de frais d'assurance pour un ticket vip;
    }

    function setVipInsurancePercent(uint256 _newVipInsuranceCostPercent) external onlyOwner virtual{
        _vipInsuranceCostPercent = _newVipInsuranceCostPercent;
        // change le % de frais d'assurance pour un ticket vip;
    }

    function getInsuranceAddress() public view virtual returns(address){
        return insuranceAdress; // retourne l'address qui recoit les frais d'assurance;
    }

    function setInsuranceAddress(address _address) external onlyOwner virtual{
        insuranceAdress = _address; // change l'address qui recoit les frais d'assurance;
    }

    function withdrawContractBalances(address recipientAddress, uint amount) external onlyOwner virtual{
        payable(recipientAddress).transfer(amount);
        _ethContractBalances[address(this)] -= amount;
    }

    function mint(address account, uint256 amount, uint256 insuranceAmount, bool _insurance) public payable{
        require(account != address(0), "Error: mint to the zero address");
        require((_totalSupply + amount) <= _maxSupply, "Error: Exceed max available tickets !");
        require(amount <= _maxBuy, "Error: Exceed max buy !");
        require(_basicTicketBalances[account] + amount <= _maxWallet, "Error: Exceed max wallet !");
        require(amount >= insuranceAmount);

        if (msg.sender != Owner && !_insurance) {
      require(msg.value >= _cost * amount , "cost error"); // verifie que le montant payé correspond bien au montant de prix de vente sans assurance;
        }
        else if (msg.sender != Owner && _insurance){
            // verifie que le montant payé correspond bien au montant de prix de vente avec assurance;
            require(msg.value >= _cost * amount + _basicInsuranceCost * insuranceAmount , "cost error");
        }
        if (_insurance && insuranceAmount >= amount){ // si assurance est true, augmente la balance d'assurance du wallet avec le montant correspondant au nomnbre de ticket acheté;
            insurance[msg.sender] += insuranceAmount; 
            payable(insuranceAdress).transfer(_basicInsuranceCost * insuranceAmount); // paye les frais d'assurance vers le wallet assurance;
            _ethContractBalances[address(this)] += msg.value - _basicInsuranceCost;
        }else{
            _ethContractBalances[address(this)] += msg.value;
        }
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _basicTicketBalances[account] += amount;
        }

        _afterTokenTransfer(address(0), account, amount);
    }

    function vipMint(address account, uint256 amount, uint256 insuranceAmount, bool _insurance) public payable{
        require(account != address(0), "Error: mint to the zero address");
        require((_totalSupply + amount) <= _maxSupply, "Error: Exceed max available tickets !");
        require(amount <= _vipSupply, "Error: Exceed max VIP tickets on sale !");
        require(amount <= _maxBuy, "Error: Exceed max buy !");
        require(_vipTicketBalances[account] + amount <= _maxWallet, "Error: Exceed max wallet !");
        require(amount >= insuranceAmount);

        if (msg.sender != Owner && !_insurance) {
      require(msg.value >= _vipCost * amount , "cost error"); // verifie que le montant payé correspond bien au montant de prix de vente sans assurance;
        }
        else if (msg.sender != Owner && _insurance){
            // verifie que le montant payé correspond bien au montant de prix de vente avec assurance;
            require(msg.value >= _vipCost * amount + _vipInsuranceCost * insuranceAmount , "cost error");
        }
        if(_insurance && insuranceAmount >= amount){ // si assurance est true, augmente la balance d'assurance VIP du wallet avec le montant correspondant au nomnbre de ticket VIP acheté;
            vipInsurance[msg.sender] += insuranceAmount;
            payable(insuranceAdress).transfer(_vipInsuranceCost * insuranceAmount); // paye les frais d'assurance VIP vers le wallet assurance;
            _ethContractBalances[address(this)] += msg.value - _vipInsuranceCost;
        }else{
            _ethContractBalances[address(this)] += msg.value;
        }

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _vipTicketBalances[account] += amount;
        }

        _afterTokenTransfer(address(0), account, amount);
    }

    function refund(address account, uint _amount) public virtual payable{
        // verifie que le caller possede bien le nombre d'assurance equivalent au nombre de ticket qu'il veut ce faire rembourser;
        require(insurance[account] == _amount && insurance[account] > 0, "Error: You don't have insurance or the insurance amount does not match the ticket amount");
        uint _Amount = _amount * _cost;
        payable(Owner).transfer((_Amount) * 10 /100); // transfert 10% de frais vers le wallet du owner;
        payable(account).transfer((_Amount) * 90 /100); // Transfert 90% restant vers le caller;
        _ethContractBalances[address(this)] -= _Amount; // retire le nombre d'ether de la balance du contract correspondant au transfert qui vient detre effectué;
        _basicTicketBalances[account] -= _amount; // retire les tickets du wallet, correspondant au montant;
        insurance[account] -= _amount; // retire le nombre d'assurance du wallet, correspondant aussi au montant;
        _totalSupply -=_amount; // remet les tickets en vente;
    }

     function refundVipTicket(address account, uint _amount) public virtual payable{
         // verifie que le caller possede bien le nombre d'assurance equivalent au nombre de ticket qu'il veut ce faire rembourser;
        require(vipInsurance[account] == _amount && vipInsurance[account] > 0, "Error: Check that you have the number of insurance corresponding to the number of tickets you want to be refunded");
        uint _Amount = _amount * _vipCost;
        payable(Owner).transfer((_Amount) * 10 /100); // transfert 10% de frais vers le wallet du owner;
        payable(account).transfer((_Amount) * 90 /100); // Transfert 90% restant vers le caller;
        _ethContractBalances[address(this)] -= _Amount; // retire le nombre d'ether de la balance du contract correspondant au transfert qui vient detre effectué;
        _vipTicketBalances[account] -= _amount; // retire les tickets du wallet, correspondant au montant;
        vipInsurance[account] -= _amount; // retire le nombre d'assurance du wallet, correspondant aussi au montant;
        _totalSupply -= _amount; // remet les tickets en vente;
    }


    // FONCTION DE BASE POUR UN SMART CONTRACT ////////////////////////////////////////////////////////////////////////////

    function transfer(address to, uint256 amount) public onlyOwner virtual returns (bool) {
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        if (msg.sender == Owner) {
            address owner = Owner;
            _approve(owner, spender, amount);
        return true;
        }
        else {
            address owner = msg.sender;
            _approve(owner, spender, amount);
        return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "Error: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Error: transfer from the zero address");
        require(to != address(0), "Error: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _basicTicketBalances[from];
        require(fromBalance >= amount, "Error: transfer amount exceeds balance");
        unchecked {
            _basicTicketBalances[from] = fromBalance - amount;

            _basicTicketBalances[to] += amount;
        }

        _afterTokenTransfer(from, to, amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Error: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    receive() external payable{
        _ethContractBalances[address(this)] += msg.value;
    }

}