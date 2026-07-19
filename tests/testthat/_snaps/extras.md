# print methods produce compact output

    Code
      print(sql_parse("SELECT 1"))
    Message
      <polyglot_ast> 1 statement (generic)
      [1] select

---

    Code
      print(sql_validate("SELECT 1"))
    Message
      <polyglot_validation> valid (generic)

---

    Code
      print(sql_validate("SELECT FROM WHERE"))
    Message
      <polyglot_validation> invalid (generic)
      [E003] Expected table name or subquery, got Where at 1:18

---

    Code
      print(sql_lineage("SELECT a FROM t"))
    Message
      <polyglot_lineage> 1 column (generic)
      a ← t

---

    Code
      print(sql_analyze("SELECT a FROM t"))
    Message
      <polyglot_analysis> shape: select (generic)
      projections: a
      relations: t

---

    Code
      print(sql_tokenize("SELECT 1"))
    Message
      <polyglot_tokens> 2 tokens
    Output
          type   text line column start end
      1 Select SELECT    1      7     0   6
      2 Number      1    1      9     7   8

