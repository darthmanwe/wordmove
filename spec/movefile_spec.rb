describe Wordmove::Movefile do
  let(:path) { File.join(TMPDIR, 'movefile.yml') }
  let(:movefile) { described_class.new(config: movefile_path_for("Movefile")) }

  context ".initialize" do
    it "instantiate a logger instance" do
      expect(movefile.logger).to be_an_instance_of(Wordmove::Logger)
    end
  end

  context ".load_env" do
    TMPDIR = "/tmp/wordmove".freeze

    let(:path) { File.join(TMPDIR, 'movefile.yml') }
    let(:dotenv_path) { File.join(TMPDIR, '.env') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:dotenv) { "OBIWAN=KENOBI" }
    let(:movefile) { described_class.new({ config: 'movefile.yml' }, path) }

    before do
      FileUtils.mkdir(TMPDIR)
      File.open(path, 'w') { |f| f.write(yaml) }
      File.open(dotenv_path, 'w') { |f| f.write(dotenv) }
      allow_any_instance_of(described_class)
        .to receive(:current_dir)
        .and_return(TMPDIR)
      allow_any_instance_of(described_class)
        .to receive(:logger)
        .and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when .env is present" do
      let(:movefile) do
        described_class.new(
          {
            config: 'movefile.yml',
            environment: 'local'
          },
          path
        )
      end

      it "loads environment variables" do
        movefile.load_dotenv

        expect(ENV['OBIWAN']).to eq('KENOBI')
      end
    end
  end

  context ".fetch" do
    TMPDIR = "/tmp/wordmove".freeze

    let(:path) { File.join(TMPDIR, 'movefile.yml') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:movefile) { described_class.new({}, path) }

    before do
      FileUtils.mkdir(TMPDIR)
      File.open(path, 'w') { |f| f.write(yaml) }
      allow_any_instance_of(described_class)
        .to receive(:current_dir)
        .and_return(TMPDIR)
      allow_any_instance_of(described_class)
        .to receive(:logger)
        .and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when Movefile is missing" do
      it 'raises an exception' do
        expect { described_class.new({}, '/tmp') }.to raise_error(Wordmove::MovefileNotFound)
      end
    end

    context "when Movefile is present" do
      it 'finds a Movefile in current dir' do
        result = movefile.options
        expect(result[:name]).to eq('Waldo')
        expect(result[:job]).to eq('Hider')
      end

      context "when movefile has no extensions" do
        let(:path) { File.join(TMPDIR, 'movefile') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "when Movefile has no extensions and has first capital" do
        let(:path) { File.join(TMPDIR, 'Movefile') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "when movefile.yaml has long extension" do
        let(:path) { File.join(TMPDIR, 'movefile.yaml') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "directories traversal" do
        before do
          @test_dir = File.join(TMPDIR, "test")
          FileUtils.mkdir(@test_dir)
        end

        it 'goes up through the directory tree and finds it' do
          movefile = described_class.new({}, @test_dir)
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end

        context 'Movefile not found, met root node' do
          let(:movefile) { described_class.new({}, '/tmp') }

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end

        context 'Movefile not found, found wp-config.php' do
          let(:movefile) { described_class.new({}, '/tmp') }

          before do
            FileUtils.touch(File.join(@test_dir, "wp-config.php"))
          end

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end
      end
    end
  end

  context ".secrets" do
    let(:path) { movefile_path_for('with_secrets') }

    it "returns all the secrets found in movefile" do
      movefile = described_class.new(config: path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_password
          local_database_host
          http://secrets.local
          ~/dev/sites/your_site
          remote_database_password
          remote_database_host
          http://secrets.example.com
          ssh_password
          ssh_host
          ftp_password
          ftp_host
          /var/www/your_site
          https://foo.bar
        ]
      )
    end

    it "returns all the secrets found in movefile excluding empty string values" do
      path = movefile_path_for('with_secrets_with_empty_local_db_password')
      movefile = described_class.new(config: path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_host
          http://secrets.local
          ~/dev/sites/your_site
          remote_database_password
          remote_database_host
          http://secrets.example.com
          ssh_password
          ssh_host
          ftp_password
          ftp_host
          /var/www/your_site
        ]
      )
    end
  end
end
