import pickle
import isa

# tokenizes the file into a 2d array, where each row in the array represents one line of assembly
def tokenize(filename):
  tokens = []
  with open(filename, "r") as f:
    for line in f:
      token = line.strip().replace(",", "").replace("\n", "").split(" ")
      tokens.append(token)
  return tokens

# creates the symbol table, meaning it needs to figure out which line corresponds with the symbol
# also generates clean formatted instructions
def pass1(filename):
  tokens = tokenize(filename)
  symbolTable = {} 
  instrLines = []
  lineNums = 1
  prevSym = False

  for line in tokens:
    itmNum = len(line)
    line[0] = line[0].lower()
    if line[0] not in isa.INSTRUCTIONS:
      if itmNum > 1:
        prevSym = False
        # if line[1] not in isa.INSTRUCTIONS: # illegal instruction
        # return -1
        lineNums += 1
        instrLines.append(line[1:])
      else:
        prevSym = True
      symbolTable.update({line[0] : lineNums})
    elif prevSym == False:
      lineNums += 1
      prevSym = False
      instrLines.append(line)
    else:
      prevSym = False
      instrLines.append(line)

#   print(f"{lineNums}: {line}")

# print(lineNums)
# print(instrLines)
# print(symbolTable)
  return symbolTable, instrLines

# needs to generate the instructions in hex
def pass2(symbolTable, instrLines):
  lineNums = 1
  
  with open("out.hex", "w") as f:
    for line in instrLines:
      opcode = isa.opcodes.get(line[0])
      match opcode:
        case 0 | 1:
          rd = int(line[1][1])
          rs1 = int(line[2][1])
          rs2 = int(line[3][1])
          hexLine = f"{int(f"{opcode:04b}{rd:05b}{rs1:05b}{rs2:05b}{0:013b}", 2):08x}"
          print(hexLine)
        case 2 | 3:
          rd_rs = int(line[1][1])
          imm = int(line[2][0])
          rb = int(line[2][3])
          hexLine = f"{int(f"{opcode:04b}{rd_rs:05b}{rb:05b}{imm:018b}", 2):08x}"
          print(hexLine)
        case 4:
          targ = line[1].lower()
          offset = symbolTable.get(targ) - lineNums
          hexLine = f"{int(f"{opcode:04b}{offset:028b}", 2):08x}"
          print(hexLine)
        case 5:
          p = int(line[1][1])
          rs1 = int(line[2][1])
          rs2 = int(line[3][1])
          cond = isa.CONDITION_CODES.get(line[4].lower())
          hexLine = f"{int(f"{opcode:04b}{p:03b}{rs1:05b}{rs2:05b}{cond:03b}{0:012b}", 2):08x}"
          print(hexLine)
        case 6:
          p = int(line[1][1])
          targ = line[2].lower()
          targ_offset = symbolTable.get(targ) - lineNums
          rcnv = line[3].lower()
          rcnv_offset = symbolTable.get(rcnv) - lineNums
          hexLine = f"{int(f"{opcode:04b}{p:03b}{targ_offset:012b}{rcnv_offset:012b}{0:01b}", 2):08x}"
          print(hexLine)
        case 7:
          rd = int(line[1][1])
          imm = int(line[2])
          hexLine = f"{int(f"{opcode:04b}{rd:05b}{imm:023b}", 2):08x}"
          print(hexLine)
        case 8 | 9:
          hexLine = f"{int(f"{opcode:04b}{0:028b}", 2):08x}"
          print(hexLine)





        

      lineNums += 1




    

# def main():

 

# TESTING
a, b = pass1("unit_test.asm")
pass2(a, b)
