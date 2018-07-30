pragma solidity ^0.4.24;

import "./EIP20Interface.sol";


contract Token is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    //sender -> caller --> allowed amount
    mapping (address => mapping (address => uint256)) public allowed;
    address dao;
    /*
    NOTE:
    The following variables are OPTIONAL `vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks

    constructor (uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;     //1000000                   // Update total supply
        name = 'Kiwi';                                   // Set the name for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }


    //only DAO is allowed to call this
    //or owner of tokens has to approve first 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value);
        require(allowance >= _value || msg.sender == dao); //approved or called by dao
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function setDao(address _dao) public {
        dao = _dao;
    }
    
}

