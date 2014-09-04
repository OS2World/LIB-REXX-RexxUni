/* RexxUni usage examples */

Call RxFuncAdd 'UniLoadFuncs', 'RexxUni', 'UniLoadFuncs'
Call UniLoadFuncs

cp = UniQueryCp()
Say 'UniQueryCp(): ' || cp
Say "UniQueryCp('UTF-8'): " || UniQueryCp('UTF-8')
Say "UniQueryCp('ASCII-7'): " || UniQueryCp('ASCII-7')
Say "UniQueryCp('UNICODE'): " || UniQueryCp('UNICODE')
Say "UniQueryCp('SUPERCODE'): " || UniQueryCp('SUPERCODE')

Say 'UniCpName(): ' || UniCpName()
Say 'UniCpName(1): ' || UniCpName(1)
Say 'UniCpName(853): ' || UniCpName(853)

test = 'Test'

t = UniXlat(test,'UNICODE',cp)
Say "c2x(UniXlat('"test"','UNICODE',"cp")): " || c2x(t)

Say "UniXlat('"t"','UTF-8','UNICODE'): " || UniXlat(t,'UTF-8','UNICODE')

Say "UniXlat('"test"',1251,"cp"): " || UniXlat(test,1251,cp)
Say "UniXlat('"test"',1): " || UniXlat(test,1251)

Call UniDropFuncs
