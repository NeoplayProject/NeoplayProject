using Neo.SmartContract.Framework;
using Neo.SmartContract.Framework.Services.Neo;
using Neo.SmartContract.Framework.Services.System;
using System;
using System.Linq;
using System.Numerics;
using System.ComponentModel;
using System.Text;
using System.Collections;

namespace Neoplaymk1
{
    public class Owned : SmartContract
    {
        private static byte[] owner;
        public static readonly byte[] neo_asset_id = { 155, 124, 255, 218, 166, 116, 190, 174, 15, 147, 14, 190, 96, 133, 175, 144, 147, 229, 254, 86, 179, 74, 92, 34, 12, 205, 207, 110, 252, 51, 111, 197 };
        public static void Owned() => owner = GetSender();
        public static void Main(){}
        public static bool IsOwner() => owner == GetSender();
        public bool TransferOwnership(byte[] newOwner)
        {
            if (IsOwner())
            {
                owner = newOwner;
                return (true);
            }
            return (false);
        }
        public static byte[] GetReceiver() => ExecutionEngine.ExecutingScriptHash;
        public static byte[] GetSender()
        {
            Transaction tx = (Transaction)ExecutionEngine.ScriptContainer;
            TransactionOutput[] reference = tx.GetReferences();
            var receiver = GetReceiver();
            foreach (TransactionOutput output in reference)
            {
                if (output.ScriptHash != receiver && output.AssetId == neo_asset_id)
                {
                    return output.ScriptHash;
                }
            }
            return new byte[] { }; 
        }
    }
    public class NPLAY : Owned
    {
        //Events
        [DisplayName("refund")]
        public static event Action<byte[], BigInteger> Refund;
        [DisplayName("transfer")]
        public static event Action<byte[], byte[], BigInteger> Transferred;
        //Variables and Getters
        public static string Name() => "NPLAY";
        public static string Symbol() => "NPLAY";
        public static byte Decimals() => 4;

        private static byte[] bank;
        private static ulong decimalFactor = 10^(ulong)Decimals();
        private static ulong totalSupply = 100000000 * decimalFactor;
        private static ulong price = 500 * decimalFactor;
        private const ulong neo_decimals = 100000000;
        private const string reroll_prefix = "Reroll";
        private int salt;
        //Main
        public static int Main()
        {
            if (Runtime.Trigger == TriggerType.Verification)
            {
                if (Runtime.CheckWitness(SuperAdmin)){
                    return true;
                }
                Transaction tx = (Transaction)Neo.SmartContract.Framework.Services.System.ExecutionEngine.ScriptContainer;
                TransactionInput[] inputs = tx.GetInputs();
                TransactionOutput[] outputs = tx.GetOutputs();
                if (inputs.Length != 1 || outputs.Length != 1) return false;
                BigInteger bn = (int)(inputs[0].PrevIndex);
                byte[] key = inputs[0].PrevHash.Concat(ConvertN(bn));
                var targetAddr = Storage.Get(Storage.CurrentContext, key);
                if (outputs[0].ScriptHash.AsBigInteger() == targetAddr.AsBigInteger()) return true;
                return false;
            }
            else if (Runtime.Trigger == TriggerType.Application)
            {
                if (method == "collect")
                {
                    var index = ConvertN((BigInteger)args[0]);
                    byte[] who = (byte[])args[1];
                    Transaction tx = (Transaction)Neo.SmartContract.Framework.Services.System.ExecutionEngine.ScriptContainer;
                    TransactionOutput[] outputs = tx.GetOutputs();
                    var key = tx.Hash.Concat(index);
                    Storage.put(Storage.CurrentContext, key, who);
                }
            }
            return false;
        }
        
        //Private functions

        private static ulong GetOutputValue()
        {
            Transaction tx = (Transaction)ExecutionEngine.ScriptContainer;
            TransactionOutput[] outputs = tx.GetOutputs();
            ulong value = 0;
            foreach (TransactionOutput output in outputs)
            {
                if (output.ScriptHash == GetReceiver() && output.AssetId == neo_asset_id)
                {
                    value += (ulong)output.Value;
                }
            }
            return value;
        }
        
        private int GetPseudoRandom()
        {
            Header h = Blockchain.GetHeader(Blockchain.GetHeight());
            ulong pr1 = h.ConsensusData+(ulong)salt;
            ulong pr2 = neo_asset_id[pr1 % 32];
            return (((int)pr1*salt) ^ (int)pr2 % 100);

        }

        //Public Functions
        public void ChangeSalt(int newSalt)
        {
            if (IsOwner()) salt = newSalt;
        }
        public static bool Init()
        {
            NPLAY.owner = GetSender(); 
            byte[] supply = Storage.Get(Storage.CurrentContext, owner);
            if(supply.Length!=0)Storage.Put(Storage.CurrentContext, owner, totalSupply);
            return true;
        }

        public static bool Buy()
        {
            byte[] sender = GetSender();
            if (sender.Length == 0) return false;
            ulong contribution_value = GetContribution(sender);
            ulong EquivalentTokens = (ulong)GetMultiplier()*contribution_value / price;
            BigInteger balance = Storage.Get(Storage.CurrentContext, sender).AsBigInteger();
            BigInteger TS = TotalSupply();
            Storage.Put(Storage.CurrentContext, sender, EquivalentTokens + balance);
            Storage.Put(Storage.CurrentContext, "totalSupply", TS - EquivalentTokens);
            return (true);

        }
        public static int GetMultiplier()
        {
            int multiplier = 0;
            Header h = Blockchain.GetHeader(Blockchain.GetHeight());
            uint blo = h.Timestamp;
            if (blo > 1525550400)
            {
                if (blo < 1525636800)
                {
                    multiplier = 150;
                }
                else if (blo < 1526155200)
                {
                    multiplier = 140;
                }
                else if (blo < 1526760000)
                {
                    multiplier = 125;
                }
                else if (blo < 1527364800)
                {
                    multiplier = 115;
                }
                else if (blo < 1527969600)
                {
                    multiplier = 105;
                }
            }
            else
            {
                multiplier = 100;
            }
            return (multiplier);
        }
        public static bool Transfer(byte[] from, byte[] to, BigInteger value)
        {
            if (value <= 0) return false;
            if (!Runtime.CheckWitness(from)) return false;
            if (from == to) return true;

            BigInteger from_balance = Storage.Get(Storage.CurrentContext, from).AsBigInteger();
            if (from_balance < value) return false;
            if (from_balance == value)
                Storage.Delete(Storage.CurrentContext, from);
            else
                Storage.Put(Storage.CurrentContext, from, from_balance - value);

            BigInteger to_balance = Storage.Get(Storage.CurrentContext, to).AsBigInteger();
            Storage.Put(Storage.CurrentContext, to, to_balance + value);
            Transferred(from, to, value);
            return true;
        }
        public static BigInteger BalanceOf(byte[] address) => Storage.Get(Storage.CurrentContext, address).AsBigInteger();
        public static BigInteger TotalSupply() => Storage.Get(Storage.CurrentContext,owner).AsBigInteger();
        public static byte[] ConvertN(BigInteger n)
        {
            switch (n)
            {
                case 0:
                    return new byte[2] { 0x00, 0x00 };
                    break;
                case 1:
                    return new byte[2] { 0x00, 0x01 };
                    break;
                case 2:
                    return new byte[2] { 0x00, 0x02 };
                    break;
                case 3:
                    return new byte[2] { 0x00, 0x03 };
                    break;
                case 4:
                    return new byte[2] { 0x00, 0x04 };
                    break;
            }
            throw new Exception("Not Supported");
        }
    }
}
