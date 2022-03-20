// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyERC20 {
    // Название токена
    string private _name;
    // Символ токена
    string private _symbol;
    // Количество нулей токена
    uint8 private _decimals;
    // Владелец контракта
    address public owner;
    // Эмиссия токена
    uint256 private _totalSupply;

    // Маппинг для хранения баланса
    mapping(address => uint256) private _balanceOf;

    // Маппинг для хранения одобренных транзакций
    mapping(address => mapping(address => uint256)) private _allowance;

    //Эвенты (ЛОГИ)
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Функция инициализации контракта ERC20("MegaToken", "MEGA")
    constructor() {
        // Указываем число нулей
        _decimals = 18;
        // Указываем название токена
        _symbol = "MEGA";
        // Указываем символ токена
        _name = "MegaToken";
        //запоминаем овнера
        owner = msg.sender;
        //минним токены овнеру
        mint(msg.sender, 10_000 * 10**decimals());
    }

    // EIP-20: стандарт токена
    // Геттеры
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf[_owner];
    }

    // Функция для перевода токенов
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // Вызов внутренней функции перевода
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Внутренняя функция для перевода токенов
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // Проверка на пустой адрес
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        // Проверка того, что отправителю хватает токенов для перевода
        require(_balanceOf[_from] >= _value, "Do not enough balance");
        // Токены списываются у отправителя
        _balanceOf[_from] -= _value;
        // Токены прибавляются получателю
        _balanceOf[_to] += _value;
        // Эвент перевода токенов
        emit Transfer(_from, _to, _value);
    }

    // Функция для перевода "одобренных" токенов
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // Отправка токенов
        _transfer(_from, _to, _value);
        // Проверка, что токены были выделены аккаунтом _from для аккаунта _to
        require(_allowance[_from][msg.sender] >= _value, "Do not enough money");
        // Уменьшаем число "одобренных" токенов
        _approve(_from, msg.sender, _allowance[_from][msg.sender] - _value);

        return true;
    }

    // Функция для "одобрения" перевода токенов
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    // Внутренняя функция для "одобрения" перевода токенов
    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    ) internal {
        // Проверка на пустой адрес
        require(_owner != address(0), "_owner the zero address");
        require(_spender != address(0), "_spender the zero address");
        // Записываем в маппинг число "одобренных" токенов
        _allowance[_owner][_spender] = _value;
        // Вызов эвента для логгирования события одобрения перевода токенов
        emit Approval(_owner, _spender, _value);
    }

    // Возвращает сумму, которую _spender может снять у _owner
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowance[_owner][_spender];
    }

    // Функция для добавления к одобряемому количеству токенов
    function increaseAllowance(address _spender, uint256 _addAmount) public {
        _approve(
            msg.sender,
            _spender,
            _allowance[msg.sender][_spender] + _addAmount
        );
    }

    // Функция для уменьшения одобряемого количества токенов
    function decreaseAllowance(address _spender, uint256 _decAmount) public {
        // Проверяем, доступно ли для msg.sender переводить по адресу _spender токены в размере _decAmount
        require(
            _allowance[msg.sender][_spender] >= _decAmount,
            "decreased allowance below zero"
        );
        _approve(
            msg.sender,
            _spender,
            _allowance[msg.sender][_spender] - _decAmount
        );
    }

    // Функция для увеличения эмиссии
    function mint(address _user, uint256 _amount) public {
        // Только овнер может минтить
        require(msg.sender == owner, "Only owner can mint new tokens");
        // Проверка на пустой адрес
        require(_user != address(0), "_user has the zero address");
        // увеличиваем эмиссию
        _totalSupply += _amount;
        // зачиляем добавленную эмиссию пользователю _user
        _balanceOf[_user] += _amount;
        // генерируем событие о передаче токенов
        emit Transfer(address(0), _user, _amount);
    }

    // Функция для сжигания токенов
    function burn(address _user, uint256 _amount) public {
        // Только овнер может минтить
        require(msg.sender == owner, "Only owner can burn new tokens");
        // Есть ли у пользователя столько на балансе
        require(_balanceOf[_user] >= _amount, "burn amount exceeds balanc");
        // уменяшаем эмиссию
        _totalSupply -= _amount;
        // уменьшаем баланс пользователя _user
        _balanceOf[_user] -= _amount;
        // генерируем событие о передаче токенов на нулевой адрес
        emit Transfer(_user, address(0), _amount);
    }
}