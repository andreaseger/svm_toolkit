print `javac libsvm/*.java`
print `jar cvf libsvm.jar libsvm/*.class libsvm/*.java COPYRIGHT`
`rm libsvm/*.class`
`mv libsvm.jar ../lib/java`