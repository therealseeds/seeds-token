pragma solidity ^0.4.13;

contract Token {
  mapping (address => uint256) public balanceOf;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);

  function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    decimals = decimalUnits;
    symbol = tokenSymbol;
    name = tokenName;
  }

  function transfer(address _to, uint256 _amount) returns (bool success) {
    require(balanceOf[msg.sender] >= _amount && balanceOf[_to] + _amount >= balanceOf[_to]);

    balanceOf[msg.sender] -= _amount;
    balanceOf[_to] += _amount;
    Transfer(msg.sender, _to, _amount);
    return true;
  }
}
/*
contract admined {
  address public admin;

  function admined() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function transferAdminship(address newAdmin) onlyAdmin {
    admin = newAdmin;
  }
}

contract AssetToken is admined, Token {
  function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) Token(0, tokenName, tokenSymbol, decimalUnits) {
    if (centralAdmin != 0) {
      admin = centralAdmin;
    } else {
      admin = msg.sender;
    }

    balanceOf[admin] = initialSupply;
    totalSupply = initialSupply;
  }

  function transfer(address _to, uint256 _value) {
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }
}*/
